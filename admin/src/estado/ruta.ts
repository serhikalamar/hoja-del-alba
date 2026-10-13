// Rutas con "#" (funcionan en GitHub Pages sin configurar nada): #/resumen, #/balance/enemigos…

import { useEffect, useState } from 'react'

export function leerRuta(): string[] {
  return decodeURIComponent(window.location.hash.replace(/^#\/?/, '')).split('/').filter(Boolean)
}

export function useRuta(): string[] {
  const [ruta, setRuta] = useState(leerRuta)
  useEffect(() => {
    const h = () => setRuta(leerRuta())
    window.addEventListener('hashchange', h)
    return () => window.removeEventListener('hashchange', h)
  }, [])
  return ruta
}

export function navegar(...partes: string[]): void {
  window.location.hash = `#/${partes.map(encodeURIComponent).join('/')}`
}

export function enlace(...partes: string[]): string {
  return `#/${partes.map(encodeURIComponent).join('/')}`
}
