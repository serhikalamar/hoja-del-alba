import { createRoot } from 'react-dom/client'
import { App } from './App'
import { ProveedorPanel } from './estado/panel'
import './estilos.css'

createRoot(document.getElementById('raiz')!).render(
  <ProveedorPanel>
    <App />
  </ProveedorPanel>,
)
