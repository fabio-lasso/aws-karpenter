# 04.11 · Depuración de Karpenter en Auto Mode con Kiro (opcional)

En esta sección usarás [Kiro CLI](https://kiro.dev/) con el [Amazon EKS MCP Server](https://github.com/awslabs/mcp) para diagnosticar y resolver problemas de scheduling mediante prompts en lenguaje natural, en lugar de comandos manuales.

[MCP (Model Context Protocol)](https://modelcontextprotocol.io/) es un estándar open-source para conectar aplicaciones de IA con sistemas externos. El EKS MCP Server permite a Kiro interactuar directamente con tu clúster EKS: gestión de recursos, logs de pods, eventos e integración con CloudWatch, todo mediante una interfaz conversacional.

## Paso 1 · Configurar los servidores MCP

```bash
mkdir -p ~/.kiro/settings/
```

```bash
cat > ~/.kiro/settings/mcp.json << 'EOF'
{
  "mcpServers": {
    "awslabs.eks-mcp-server": {
      "command": "uvx",
      "args": [
        "awslabs.eks-mcp-server@latest",
        "--allow-write",
        "--allow-sensitive-data-access"
      ],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      },
      "autoApprove": [],
      "disabled": false
    },
    "aws-knowledge-mcp-server-mcp": {
      "command": "uvx",
      "args": [
        "fastmcp",
        "run",
        "https://knowledge-mcp.global.api.aws"
      ],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      }
    }
  }
}
EOF
```

## Paso 2 · Autenticarse con AWS Builder ID

Kiro CLI ya está instalado en el entorno de code server.

```bash
kiro-cli login --use-device-flow
```

Elige el método de login: **Use for Free with Builder ID** (en eventos de AWS o cuentas personales) o **Use with Pro license**. Abre la URL mostrada en el navegador, confirma y permite el acceso. Verás un mensaje de confirmación en la terminal.

## Paso 3 · Iniciar el chat de Kiro

```bash
kiro-cli chat
```

Comandos básicos:

- Limpiar la conversación: `/clear`
- Cerrar la sesión: `/quit`

### Verificar acceso al clúster

```
List the number of pods in the kube-system namespace in this cluster
```

```
List the number of NodePools in this cluster
```

> [!NOTE]
> Este workshop limita a Kiro a permisos RBAC para gestionar los recursos de Kubernetes del clúster. No se permite gestionar el clúster a través de la API de EKS.

Kiro pedirá permiso al usar una herramienta no confiable:

```
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:
```

Se recomienda `y` para revisar decisión por decisión, o `t` si confías en las acciones.

## Paso 4 · Desplegar el entorno del reto

En una nueva terminal, despliega una aplicación frontend con un problema de scheduling deliberado:

```bash
debug_with_kiro_challenge
```

Verás los pods atascados en estado `Pending`.

## Reto: diagnosticar y arreglar los pods pendientes

Objetivo: usar Kiro CLI con el EKS MCP Server para investigar por qué los pods frontend están `Pending`, identificar la causa raíz y aplicar una solución.

```bash
kiro-cli chat
```

> 💡 Prompt sugerido: pide a Kiro que inspeccione los eventos del pod frontend, la configuración de los NodePools y las restricciones de `nodeSelector`/affinity del pod, e identifique por qué no se puede programar.

## Qué aprendimos

- Configurar y usar Kiro CLI con el Amazon EKS MCP Server para interactuar con un clúster EKS mediante lenguaje natural.
- Kiro puede diagnosticar problemas de scheduling inspeccionando eventos de pods, configuraciones de NodePool y estado de nodos, de forma conversacional.
- El EKS MCP Server permite a Kiro leer y modificar recursos de Kubernetes, acceder a logs y eventos, y recuperar métricas de CloudWatch desde una sola interfaz.
- Al depurar scheduling, las señales clave son los eventos del pod (especialmente `FailedScheduling`), la disponibilidad del NodePool y las restricciones de `nodeSelector`/affinity.

---

⬅️ Anterior: [Debugging](10-debugging.md) · ➡️ Siguiente: [Observabilidad](12-observabilidad.md)
