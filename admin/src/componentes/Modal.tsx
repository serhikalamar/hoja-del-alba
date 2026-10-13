import { useEffect, type ReactNode } from 'react'

interface Props {
  titulo: string
  children: ReactNode
  pie?: ReactNode
  onCerrar: () => void
  ancho?: number
}

/** Ventana modal sencilla (Esc para cerrar). */
export function Modal({ titulo, children, pie, onCerrar, ancho }: Props) {
  useEffect(() => {
    const h = (e: KeyboardEvent) => { if (e.key === 'Escape') onCerrar() }
    window.addEventListener('keydown', h)
    return () => window.removeEventListener('keydown', h)
  }, [onCerrar])
  return (
    <div className="fondo-modal" onMouseDown={(e) => { if (e.target === e.currentTarget) onCerrar() }}>
      <div className="modal" role="dialog" aria-modal="true" aria-label={titulo} style={ancho ? { width: `min(${ancho}px, 100%)` } : undefined}>
        <div className="modal-cab">
          <h2>{titulo}</h2>
          <button className="plano" onClick={onCerrar} aria-label="Cerrar">✕</button>
        </div>
        <div className="modal-cuerpo">{children}</div>
        {pie && <div className="modal-pie">{pie}</div>}
      </div>
    </div>
  )
}

interface ConfirmarProps {
  titulo: string
  children: ReactNode
  textoSi: string
  peligro?: boolean
  ocupado?: boolean
  onSi: () => void
  onNo: () => void
}

export function Confirmar({ titulo, children, textoSi, peligro, ocupado, onSi, onNo }: ConfirmarProps) {
  return (
    <Modal
      titulo={titulo}
      onCerrar={onNo}
      pie={
        <>
          <button onClick={onNo}>Cancelar</button>
          <button className={peligro ? 'peligro' : 'primario'} onClick={onSi} disabled={ocupado}>{textoSi}</button>
        </>
      }
    >
      {children}
    </Modal>
  )
}
