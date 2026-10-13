// Tests de la capa de API sin red: configuración, claves secretas, email sintético y traducción de errores.

import { describe, expect, it } from 'vitest'
import { comprobarConfiguracion, emailDe, esClaveSecreta, validarUsuario } from './config'
import { ApiDemo } from './demo'
import { traducirError } from './supabase'
import type { PanelApi } from './tipos'

const jwt = (payload: object) => `eyJhbGciOiJIUzI1NiJ9.${btoa(JSON.stringify(payload)).replace(/=+$/, '')}.firma`

describe('configuración', () => {
  it('sin URL o clave → modo demo', () => {
    expect(comprobarConfiguracion('', '', '').problema).toMatch(/no está configurado/)
    expect(comprobarConfiguracion('https://xxxxxxxxxxxx.supabase.co', 'k', '').problema).toMatch(/ejemplo/)
  })
  it('se niega a usar claves secretas', () => {
    expect(esClaveSecreta('sb_secret_abc')).toBe(true)
    expect(esClaveSecreta(jwt({ role: 'service_role' }))).toBe(true)
    expect(esClaveSecreta(jwt({ role: 'anon' }))).toBe(false)
    expect(esClaveSecreta('sb_publishable_abc')).toBe(false)
    const c = comprobarConfiguracion('https://abc.supabase.co', 'sb_secret_abc', '')
    expect(c.problema).toMatch(/SECRETA/)
    expect(c.clave).toBe('')
  })
  it('configuración válida con la plantilla por defecto', () => {
    const c = comprobarConfiguracion('https://abc.supabase.co/', 'sb_publishable_abc', '')
    expect(c.problema).toBeNull()
    expect(c.url).toBe('https://abc.supabase.co')
    expect(c.plantilla).toBe('{usuario}@jugadores.valdehierro.app')
  })
  it('email sintético y reglas del usuario (las del juego)', () => {
    expect(emailDe(' Pepe ', '{usuario}@jugadores.valdehierro.app')).toBe('pepe@jugadores.valdehierro.app')
    expect(emailDe('pepe', 'yo+{usuario}@gmail.com')).toBe('yo+pepe@gmail.com')
    expect(validarUsuario('pe')).not.toBeNull()
    expect(validarUsuario('peñas')).not.toBeNull()
    expect(validarUsuario('sergi_1')).toBeNull()
  })
})

describe('errores de Supabase en español', () => {
  it('códigos documentados en backend/README.md', () => {
    expect(traducirError({ code: '42501', hint: 'no_admin', message: 'x' }).codigo).toBe('no_admin')
    expect(traducirError({ code: 'P0002', hint: 'no_existe', message: 'x' }).codigo).toBe('no_existe')
    expect(traducirError({ code: '22023', hint: 'no_es_borrador', message: 'x' }).codigo).toBe('no_es_borrador')
    expect(traducirError({ code: '22023', hint: 'ya_publicada', message: 'x' }).codigo).toBe('ya_publicada')
    expect(traducirError({ code: 'PGRST202', message: 'x' }).codigo).toBe('falta_funcion')
    expect(traducirError({ code: 'invalid_credentials', message: 'Invalid login credentials' }).codigo).toBe('credenciales')
    expect(traducirError(new TypeError('Failed to fetch')).codigo).toBe('red')
  })
})

describe('modo demo', () => {
  it('es de solo lectura', async () => {
    const api: PanelApi = new ApiDemo()
    await expect(api.crearBorrador({}, null)).rejects.toThrow(/Modo demo/)
    await expect(api.publicar(1)).rejects.toThrow(/Modo demo/)
    expect(await api.esAdmin()).toBe(false)
    const r = await api.resumen()
    expect(r.ejemplo).toBe(true)
    expect((await api.personajes('', 0, 10)).length).toBe(10)
  })
})
