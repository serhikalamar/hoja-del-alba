// Carga los valores base (admin/public/data/*.json, generados con `make datos`).

import type { DatosBase } from '../tipos/datos'

const FICHEROS = ['enemigos', 'piezas', 'minerales', 'zonas', 'misiones', 'economia', 'esquema'] as const

export async function cargarDatos(): Promise<DatosBase> {
  const base = import.meta.env.BASE_URL
  const leidos = await Promise.all(
    FICHEROS.map(async (f) => {
      const r = await fetch(`${base}data/${f}.json`, { cache: 'no-cache' })
      if (!r.ok) throw new Error(`No se pudo cargar data/${f}.json (${r.status}). ¿Has ejecutado "make datos"?`)
      return [f, await r.json()] as const
    }),
  )
  return Object.fromEntries(leidos) as unknown as DatosBase
}
