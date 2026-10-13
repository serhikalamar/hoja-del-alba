// Estado global del panel: datos base, sesión, borrador en edición (con deshacer y copia local), servidor.

import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { configuracion, crearApi, ErrorPanel, type ConfigPublicada, type FilaConfig, type PanelApi, type Sesion } from '../api'
import { cargarDatos } from '../datos/cargar'
import { diferencias } from '../logica/diff'
import { documentoFinal, ponerValor, restaurar, soloApartados } from '../logica/documento'
import { borrarRespaldo, guardarPreferencia, guardarRespaldo, leerPreferencia, leerRespaldo, type Respaldo } from '../logica/respaldo'
import type { DatosBase } from '../tipos/datos'
import type { GameTuning, Json, Ruta } from '../tipos/tuning'

export interface EstadoBorrador {
  doc: GameTuning
  nota: string
  /** id en game_config (null = aún no se ha guardado en Supabase). */
  id: number | null
  /** Lo que hay en el servidor para este borrador (o la publicada, si aún no existe): para saber si hay cambios sin guardar. */
  guardadoDoc: GameTuning
  guardadoNota: string
  actualizado: string | null
}

export interface Aviso { id: number; texto: string; tipo: 'info' | 'ok' | 'error' }

export interface Panel {
  api: PanelApi
  modo: 'supabase' | 'demo'
  problemaConfig: string | null
  datos: DatosBase | null
  errorDatos: string | null
  sesion: Sesion | null
  comprobandoSesion: boolean
  esAdmin: boolean
  invitado: boolean
  /** Solo un admin con Supabase puede guardar y publicar. */
  puedeEscribir: boolean
  publicada: ConfigPublicada | null
  configs: FilaConfig[]
  borrador: EstadoBorrador
  sucio: boolean
  puedeDeshacer: boolean
  respaldoPendiente: Respaldo | null
  ocupado: string | null
  autoguardado: boolean
  avisos: Aviso[]

  cambiar: (ruta: Ruta, valor: Json) => void
  restaurar: (rutas: Ruta[]) => void
  reemplazar: (doc: GameTuning) => void
  deshacer: () => void
  setNota: (nota: string) => void
  setAutoguardado: (v: boolean) => void
  guardar: () => Promise<boolean>
  publicar: () => Promise<boolean>
  descartar: () => Promise<void>
  abrirBorrador: (fila: FilaConfig) => void
  empezarDesde: (data: GameTuning, nota: string) => void
  volverA: (version: number) => Promise<boolean>
  recargar: () => Promise<void>
  recuperarRespaldo: () => void
  olvidarRespaldo: () => void
  entrar: (usuario: string, contrasena: string) => Promise<void>
  salir: () => Promise<void>
  entrarComoInvitado: () => void
  notificar: (texto: string, tipo?: Aviso['tipo']) => void
  cerrarAviso: (id: number) => void
}

const Ctx = createContext<Panel | null>(null)

export function usePanel(): Panel {
  const p = useContext(Ctx)
  if (!p) throw new Error('usePanel fuera de ProveedorPanel')
  return p
}

const VACIO: EstadoBorrador = { doc: {}, nota: '', id: null, guardadoDoc: {}, guardadoNota: '', actualizado: null }
const ORIGEN = `${configuracion.problema ? 'demo' : 'supabase'}:${configuracion.url}`

function mismoDoc(a: GameTuning, b: GameTuning): boolean {
  return diferencias(soloApartados(a) as Json, soloApartados(b) as Json).length === 0
}

function desdeFila(fila: FilaConfig): EstadoBorrador {
  const doc = soloApartados(fila.data ?? {})
  return { doc, nota: fila.note ?? '', id: fila.id, guardadoDoc: doc, guardadoNota: fila.note ?? '', actualizado: fila.updated_at }
}

function desdePublicada(pub: ConfigPublicada | null): EstadoBorrador {
  const doc = soloApartados(pub?.data ?? {})
  return { doc, nota: '', id: null, guardadoDoc: doc, guardadoNota: '', actualizado: null }
}

export function ProveedorPanel({ children }: { children: ReactNode }) {
  const api = useMemo(() => crearApi(), [])
  const [datos, setDatos] = useState<DatosBase | null>(null)
  const [errorDatos, setErrorDatos] = useState<string | null>(null)
  const [sesion, setSesion] = useState<Sesion | null>(null)
  const [comprobandoSesion, setComprobando] = useState(true)
  const [esAdmin, setEsAdmin] = useState(false)
  const [invitado, setInvitado] = useState(false)
  const [publicada, setPublicada] = useState<ConfigPublicada | null>(null)
  const [configs, setConfigs] = useState<FilaConfig[]>([])
  const [borrador, setBorrador] = useState<EstadoBorrador>(VACIO)
  const [pila, setPila] = useState<GameTuning[]>([])
  const [respaldoPendiente, setRespaldoPendiente] = useState<Respaldo | null>(null)
  const [ocupado, setOcupado] = useState<string | null>(null)
  const [autoguardado, setAutoguardadoState] = useState(() => leerPreferencia('autoguardado', 'si') === 'si')
  const [avisos, setAvisos] = useState<Aviso[]>([])
  const siguienteAviso = useRef(1)

  const puedeEscribir = api.modo === 'supabase' && !!sesion && esAdmin
  const sucio = !mismoDoc(borrador.doc, borrador.guardadoDoc) || borrador.nota.trim() !== borrador.guardadoNota.trim()

  const notificar = useCallback((texto: string, tipo: Aviso['tipo'] = 'info') => {
    const id = siguienteAviso.current++
    setAvisos((a) => [...a.slice(-3), { id, texto, tipo }])
    window.setTimeout(() => setAvisos((a) => a.filter((x) => x.id !== id)), tipo === 'error' ? 9000 : 4500)
  }, [])
  const cerrarAviso = useCallback((id: number) => setAvisos((a) => a.filter((x) => x.id !== id)), [])

  const errorTexto = (e: unknown) => (e instanceof ErrorPanel ? e.message : e instanceof Error ? e.message : String(e))

  // Datos base
  useEffect(() => {
    cargarDatos().then(setDatos).catch((e: unknown) => setErrorDatos(errorTexto(e)))
  }, [])

  /** Mira si hay una copia local distinta de lo que se acaba de cargar. */
  const revisarRespaldo = useCallback((cargado: EstadoBorrador) => {
    const r = leerRespaldo()
    if (!r || r.origen !== ORIGEN) return
    if (api.modo === 'demo') {
      setBorrador({ ...cargado, doc: soloApartados(r.doc), nota: r.nota })
      return
    }
    if (r.id === cargado.id && (!mismoDoc(r.doc, cargado.doc) || r.nota !== cargado.nota)) setRespaldoPendiente(r)
  }, [api.modo])

  const cargarServidor = useCallback(async (admin: boolean, elegirBorrador = true) => {
    const pub = await api.publicada().catch(() => null)
    setPublicada(pub)
    let cs: FilaConfig[] = []
    if (admin) {
      cs = await api.configs().catch((e: unknown) => { notificar(errorTexto(e), 'error'); return [] })
      setConfigs(cs)
    }
    if (!elegirBorrador) return
    const borradores = cs.filter((c) => c.status === 'draft').sort((a, b) => b.updated_at.localeCompare(a.updated_at))
    const cargado = borradores[0] ? desdeFila(borradores[0]) : desdePublicada(pub)
    setBorrador(cargado)
    setPila([])
    revisarRespaldo(cargado)
  }, [api, notificar, revisarRespaldo])

  // Sesión al arrancar
  useEffect(() => {
    let vivo = true
    ;(async () => {
      try {
        const s = await api.sesion()
        if (!vivo) return
        setSesion(s)
        let admin = false
        if (s) admin = await api.esAdmin().catch(() => false)
        if (!vivo) return
        setEsAdmin(admin)
        if (api.modo === 'demo' || s) await cargarServidor(admin)
      } finally {
        if (vivo) setComprobando(false)
      }
    })()
    return () => { vivo = false }
  }, [api, cargarServidor])

  // Copia local del borrador
  useEffect(() => {
    if (comprobandoSesion) return
    const t = window.setTimeout(() => {
      const hayAlgo = api.modo === 'demo' ? Object.keys(borrador.doc).length > 0 || borrador.nota !== '' : sucio
      if (hayAlgo) {
        guardarRespaldo({ doc: borrador.doc, nota: borrador.nota, id: borrador.id, origen: ORIGEN, fecha: new Date().toISOString() })
      } else if (!respaldoPendiente) {
        borrarRespaldo()
      }
    }, 400)
    return () => window.clearTimeout(t)
  }, [borrador, sucio, api.modo, comprobandoSesion, respaldoPendiente])

  // Aviso al cerrar la pestaña con cambios sin guardar en Supabase
  useEffect(() => {
    if (!puedeEscribir || !sucio) return
    const h = (e: BeforeUnloadEvent) => { e.preventDefault() }
    window.addEventListener('beforeunload', h)
    return () => window.removeEventListener('beforeunload', h)
  }, [puedeEscribir, sucio])

  const borradorRef = useRef(borrador)
  borradorRef.current = borrador
  const pilaRef = useRef(pila)
  pilaRef.current = pila

  const cambiarDoc = useCallback((f: (d: GameTuning) => GameTuning) => {
    const b = borradorRef.current
    const nuevo = f(b.doc)
    if (nuevo === b.doc || mismoDoc(nuevo, b.doc)) return
    const nb = { ...b, doc: nuevo }
    borradorRef.current = nb
    pilaRef.current = [...pilaRef.current.slice(-99), b.doc]
    setPila(pilaRef.current)
    setBorrador(nb)
  }, [])

  const cambiar = useCallback((ruta: Ruta, valor: Json) => {
    if (!datos) return
    cambiarDoc((d) => ponerValor(d, datos, ruta, valor))
  }, [datos, cambiarDoc])

  const restaurarRutas = useCallback((rutas: Ruta[]) => {
    if (!datos) return
    cambiarDoc((d) => rutas.reduce((acc, r) => restaurar(acc, datos, r), d))
  }, [datos, cambiarDoc])

  const reemplazar = useCallback((doc: GameTuning) => cambiarDoc(() => soloApartados(doc)), [cambiarDoc])

  const deshacer = useCallback(() => {
    const p = pilaRef.current
    if (p.length === 0) return
    const anterior = p[p.length - 1]
    pilaRef.current = p.slice(0, -1)
    setPila(pilaRef.current)
    setBorrador((b) => ({ ...b, doc: anterior }))
  }, [])

  const setNota = useCallback((nota: string) => setBorrador((b) => ({ ...b, nota: nota.slice(0, 500) })), [])

  const setAutoguardado = useCallback((v: boolean) => {
    setAutoguardadoState(v)
    guardarPreferencia('autoguardado', v ? 'si' : 'no')
  }, [])

  /** Guarda el borrador en Supabase (lo crea si aún no existe). Devuelve la fila guardada o null si falla. */
  const guardarFila = useCallback(async (): Promise<FilaConfig | null> => {
    if (!puedeEscribir) {
      notificar(api.modo === 'demo' ? 'Modo demo: no se puede guardar en Supabase. Usa «Exportar JSON».' : 'Solo lectura: tu usuario no es admin.', 'error')
      return null
    }
    const b = borradorRef.current
    setOcupado('Guardando…')
    try {
      const data = documentoFinal(b.doc)
      const fila = b.id === null ? await api.crearBorrador(data, b.nota.trim() || null) : await api.guardarBorrador(b.id, data, b.nota.trim() || null)
      const actualizar = (actual: EstadoBorrador): EstadoBorrador => ({
        ...actual,
        id: fila.id,
        guardadoDoc: b.doc,
        guardadoNota: b.nota,
        actualizado: fila.updated_at,
      })
      // La ref se pone ya, para que quien espere a guardar (publicar) vea el id nuevo sin esperar al render.
      borradorRef.current = actualizar(borradorRef.current)
      setBorrador(actualizar)
      setConfigs((cs) => [fila, ...cs.filter((c) => c.id !== fila.id)].sort((x, y) => y.id - x.id))
      return fila
    } catch (e) {
      notificar(errorTexto(e), 'error')
      return null
    } finally {
      setOcupado(null)
    }
  }, [api, puedeEscribir, notificar])

  const guardar = useCallback(async (): Promise<boolean> => (await guardarFila()) !== null, [guardarFila])

  // Autoguardado (8 s después del último cambio)
  useEffect(() => {
    if (!puedeEscribir || !autoguardado || !sucio || ocupado) return
    const t = window.setTimeout(() => { void guardar() }, 8000)
    return () => window.clearTimeout(t)
  }, [borrador.doc, borrador.nota, puedeEscribir, autoguardado, sucio, ocupado, guardar])

  const recargar = useCallback(async () => {
    await cargarServidor(esAdmin)
  }, [cargarServidor, esAdmin])

  const publicar = useCallback(async (): Promise<boolean> => {
    if (!puedeEscribir) return false
    let id = borradorRef.current.id
    if (sucio || id === null) {
      const fila = await guardarFila()
      if (!fila) return false
      id = fila.id
    }
    if (id === null) { notificar('No hay borrador que publicar.', 'error'); return false }
    setOcupado('Publicando…')
    try {
      const fila = await api.publicar(id)
      borrarRespaldo()
      setRespaldoPendiente(null)
      await cargarServidor(true)
      notificar(`Publicada la versión ${fila.version}. Los jugadores la recibirán al abrir el juego.`, 'ok')
      return true
    } catch (e) {
      notificar(errorTexto(e), 'error')
      return false
    } finally {
      setOcupado(null)
    }
  }, [api, puedeEscribir, sucio, guardarFila, cargarServidor, notificar])

  const descartar = useCallback(async () => {
    const b = borradorRef.current
    if (b.id !== null && puedeEscribir) {
      setOcupado('Borrando…')
      try {
        await api.borrarBorrador(b.id)
        notificar(`Borrador ${b.id} borrado.`, 'ok')
      } catch (e) {
        notificar(errorTexto(e), 'error')
      } finally {
        setOcupado(null)
      }
    }
    borrarRespaldo()
    setRespaldoPendiente(null)
    if (api.modo === 'supabase' && sesion) {
      await cargarServidor(esAdmin, false)
    }
    setBorrador(desdePublicada(publicada))
    setPila([])
  }, [api, puedeEscribir, sesion, esAdmin, publicada, cargarServidor, notificar])

  const abrirBorrador = useCallback((fila: FilaConfig) => {
    setBorrador(desdeFila(fila))
    setPila([])
    setRespaldoPendiente(null)
  }, [])

  const empezarDesde = useCallback((data: GameTuning, nota: string) => {
    const pub = desdePublicada(publicada)
    setPila((p) => [...p.slice(-99), borradorRef.current.doc])
    setBorrador({ ...pub, doc: soloApartados(data), nota })
  }, [publicada])

  const volverA = useCallback(async (version: number): Promise<boolean> => {
    if (!puedeEscribir) return false
    setOcupado('Volviendo atrás…')
    try {
      const fila = await api.volverA(version)
      await cargarServidor(true, !sucio)
      notificar(`Publicada la versión ${fila.version} (copia de la ${version}).`, 'ok')
      return true
    } catch (e) {
      notificar(errorTexto(e), 'error')
      return false
    } finally {
      setOcupado(null)
    }
  }, [api, puedeEscribir, sucio, cargarServidor, notificar])

  const recuperarRespaldo = useCallback(() => {
    const r = respaldoPendiente
    if (!r) return
    setPila((p) => [...p.slice(-99), borradorRef.current.doc])
    setBorrador((b) => ({ ...b, doc: soloApartados(r.doc), nota: r.nota }))
    setRespaldoPendiente(null)
    notificar('Recuperados los cambios de este navegador. Guárdalos para que lleguen a Supabase.', 'ok')
  }, [respaldoPendiente, notificar])

  const olvidarRespaldo = useCallback(() => {
    borrarRespaldo()
    setRespaldoPendiente(null)
  }, [])

  const entrar = useCallback(async (usuario: string, contrasena: string) => {
    const s = await api.entrar(usuario, contrasena)
    setSesion(s)
    setInvitado(false)
    const admin = await api.esAdmin().catch(() => false)
    setEsAdmin(admin)
    await cargarServidor(admin)
    notificar(admin ? `Hola, ${s.usuario}. Eres admin.` : `Hola, ${s.usuario}. No eres admin: solo lectura.`, admin ? 'ok' : 'info')
  }, [api, cargarServidor, notificar])

  const salir = useCallback(async () => {
    await api.salir()
    setSesion(null)
    setEsAdmin(false)
    setConfigs([])
    setPublicada(null)
    setBorrador(VACIO)
    setPila([])
    setRespaldoPendiente(null)
    setInvitado(false)
  }, [api])

  const entrarComoInvitado = useCallback(() => {
    setInvitado(true)
    void cargarServidor(false)
  }, [cargarServidor])

  const valor: Panel = {
    api,
    modo: api.modo,
    problemaConfig: configuracion.problema,
    datos,
    errorDatos,
    sesion,
    comprobandoSesion,
    esAdmin,
    invitado,
    puedeEscribir,
    publicada,
    configs,
    borrador,
    sucio,
    puedeDeshacer: pila.length > 0,
    respaldoPendiente,
    ocupado,
    autoguardado,
    avisos,
    cambiar,
    restaurar: restaurarRutas,
    reemplazar,
    deshacer,
    setNota,
    setAutoguardado,
    guardar,
    publicar,
    descartar,
    abrirBorrador,
    empezarDesde,
    volverA,
    recargar,
    recuperarRespaldo,
    olvidarRespaldo,
    entrar,
    salir,
    entrarComoInvitado,
    notificar,
    cerrarAviso,
  }
  return <Ctx.Provider value={valor}>{children}</Ctx.Provider>
}
