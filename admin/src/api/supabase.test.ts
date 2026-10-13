// ApiSupabase contra un servidor falso (Auth + PostgREST mínimos) en localhost: comprueba las peticiones que hace
// el panel (rutas, cabeceras, cuerpos) y cómo trata las respuestas y los errores. Sin red ni proyecto real.

import { createServer, type IncomingMessage, type Server } from 'node:http'
import type { AddressInfo } from 'node:net'
import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { comprobarConfiguracion } from './config'
import { ApiSupabase } from './supabase'

interface Peticion { metodo: string; ruta: string; cabeceras: IncomingMessage['headers']; cuerpo: unknown }

const CLAVE = 'sb_publishable_de_prueba'
const TOKEN = 'token-de-admin'
let servidor: Server
let url = ''
const peticiones: Peticion[] = []
const filas: Record<string, unknown>[] = []
let siguienteId = 1

function fila(extra: Record<string, unknown>) {
  return {
    id: siguienteId++, version: null, status: 'draft', schema_version: 1, note: null, created_by: 'u1',
    created_at: '2026-10-13T20:00:00Z', updated_at: '2026-10-13T20:00:00Z', published_at: null, published_by: null, ...extra,
  }
}

beforeAll(async () => {
  // Node 20 no trae WebSocket y supabase-js lo pide al crear el cliente (Realtime, que el panel no usa).
  const g = globalThis as { WebSocket?: unknown }
  g.WebSocket ??= class {}
  servidor = createServer((req, res) => {
    let datos = ''
    req.on('data', (c) => { datos += c })
    req.on('end', () => {
      const ruta = req.url ?? ''
      const cuerpo = datos ? JSON.parse(datos) : null
      peticiones.push({ metodo: req.method ?? '', ruta, cabeceras: req.headers, cuerpo })
      const json = (estado: number, x: unknown) => {
        res.writeHead(estado, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify(x))
      }
      const admin = req.headers.authorization === `Bearer ${TOKEN}`
      if (ruta.startsWith('/auth/v1/token')) {
        if (cuerpo?.password !== 'buena') return json(400, { code: 'invalid_credentials', error_code: 'invalid_credentials', msg: 'Invalid login credentials' })
        return json(200, {
          access_token: TOKEN, token_type: 'bearer', expires_in: 3600, expires_at: Math.floor(Date.now() / 1000) + 3600, refresh_token: 'r',
          user: { id: 'u1', aud: 'authenticated', role: 'authenticated', email: cuerpo.email, app_metadata: {}, user_metadata: {}, created_at: '2026-01-01T00:00:00Z' },
        })
      }
      if (ruta.startsWith('/auth/v1/logout')) { res.writeHead(204); return res.end() }
      if (ruta.startsWith('/rest/v1/rpc/is_admin')) return json(200, admin)
      if (ruta.startsWith('/rest/v1/rpc/published_config')) return json(200, [])
      if (!admin) return json(401, { code: '42501', hint: 'no_admin', message: 'solo admins' })
      if (ruta.startsWith('/rest/v1/rpc/config_diff')) {
        return json(200, { from_version: null, schema_version_before: null, schema_version_after: 1, changes: [{ path: 'enemies/rat/hp', before: null, after: 15 }], total: 1, truncated: false })
      }
      if (ruta.startsWith('/rest/v1/rpc/publish_config')) {
        const f = filas.find((x) => x.id === cuerpo.draft_id)
        if (!f || f.status !== 'draft') return json(400, { code: '22023', hint: 'no_es_borrador', message: 'no es un borrador' })
        Object.assign(f, { status: 'published', version: 1, published_at: '2026-10-13T21:00:00Z' })
        return json(200, f)
      }
      if (ruta.startsWith('/rest/v1/rpc/rollback_config')) return json(400, { code: '22023', hint: 'ya_publicada', message: 'ya publicada' })
      if (ruta.startsWith('/rest/v1/rpc/admin_characters')) return json(200, [])
      if (ruta.startsWith('/rest/v1/game_config')) {
        const id = Number(/id=eq\.(\d+)/.exec(ruta)?.[1])
        if (req.method === 'GET') return json(200, [...filas].reverse())
        if (req.method === 'POST') {
          const f = fila(cuerpo)
          filas.push(f)
          // .single() pide un objeto
          return json(201, String(req.headers.accept).includes('vnd.pgrst.object') ? f : [f])
        }
        if (req.method === 'PATCH') {
          const f = filas.find((x) => x.id === id && x.status === 'draft')
          if (!f) return json(200, [])
          Object.assign(f, cuerpo, { updated_at: '2026-10-13T20:30:00Z' })
          return json(200, [f])
        }
        if (req.method === 'DELETE') {
          const i = filas.findIndex((x) => x.id === id && x.status === 'draft')
          if (i < 0) return json(200, [])
          return json(200, filas.splice(i, 1).map((x) => ({ id: x.id })))
        }
      }
      json(404, { code: 'PGRST202', message: `no existe ${ruta}` })
    })
  })
  await new Promise<void>((ok) => servidor.listen(0, '127.0.0.1', ok))
  url = `http://127.0.0.1:${(servidor.address() as AddressInfo).port}`
})

afterAll(() => new Promise<void>((ok) => servidor.close(() => ok())))

describe('ApiSupabase contra un servidor falso', () => {
  it('flujo completo: entrar, crear, guardar, diff, publicar, errores', async () => {
    const api = new ApiSupabase(comprobarConfiguracion(url, CLAVE, ''))

    await expect(api.entrar('sergi', 'mala')).rejects.toMatchObject({ codigo: 'credenciales' })
    const s = await api.entrar('Sergi', 'buena')
    expect(s.usuario).toBe('sergi')
    const login = peticiones.filter((p) => p.ruta.startsWith('/auth/v1/token')).at(-1)!
    expect(login.ruta).toContain('grant_type=password')
    expect(login.cuerpo).toMatchObject({ email: 'sergi@jugadores.valdehierro.app', password: 'buena' })
    expect(login.cabeceras.apikey).toBe(CLAVE)

    expect(await api.esAdmin()).toBe(true)
    const rpc = peticiones.at(-1)!
    expect(rpc.metodo).toBe('POST')
    expect(rpc.cabeceras.authorization).toBe(`Bearer ${TOKEN}`)
    expect(rpc.cabeceras.apikey).toBe(CLAVE)

    expect(await api.publicada()).toBeNull()

    const creado = await api.crearBorrador({ enemies: { rat: { hp: 15 } } }, 'Prueba')
    expect(creado.id).toBe(1)
    const alta = peticiones.at(-1)!
    expect(alta.metodo).toBe('POST')
    expect(alta.ruta).toMatch(/^\/rest\/v1\/game_config/)
    // Solo se escriben data, schema_version y note; schemaVersion va también dentro de data.
    expect(Object.keys(alta.cuerpo as object).sort()).toEqual(['data', 'note', 'schema_version'])
    expect(alta.cuerpo).toMatchObject({ data: { schemaVersion: 1, enemies: { rat: { hp: 15 } } }, schema_version: 1, note: 'Prueba' })

    const guardado = await api.guardarBorrador(1, { enemies: { rat: { hp: 16 } } }, null)
    expect(guardado.updated_at).toBe('2026-10-13T20:30:00Z')
    expect(peticiones.at(-1)!.metodo).toBe('PATCH')
    expect(peticiones.at(-1)!.ruta).toContain('id=eq.1')

    const d = await api.diff(1)
    expect(d.total).toBe(1)
    expect(peticiones.at(-1)!.cuerpo).toEqual({ draft_id: 1 })

    const pub = await api.publicar(1)
    expect(pub.status).toBe('published')
    expect(pub.version).toBe(1)

    // Ya no es borrador: PATCH devuelve [] → error claro; publicar otra vez → no_es_borrador.
    await expect(api.guardarBorrador(1, {}, null)).rejects.toMatchObject({ codigo: 'no_es_borrador' })
    await expect(api.publicar(1)).rejects.toMatchObject({ codigo: 'no_es_borrador' })
    await expect(api.volverA(1)).rejects.toMatchObject({ codigo: 'ya_publicada' })
    await expect(api.borrarBorrador(1)).rejects.toMatchObject({ codigo: 'no_es_borrador' })

    expect((await api.configs()).length).toBe(1)
    expect(await api.personajes('  ', 0, 25)).toEqual([])
    expect(peticiones.at(-1)!.cuerpo).toEqual({ search: null, page_size: 25, page: 0 })

    await api.salir()
    await expect(api.configs()).rejects.toMatchObject({ codigo: 'no_admin' })
  })
})
