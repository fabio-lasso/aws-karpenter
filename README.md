# InterRapidísimo · Karpenter Workshop

**Ejecución de cargas de trabajo eficientes en cómputo con Karpenter y Amazon EKS Auto Mode**

Documentación base en español del workshop de AWS orientado a provisionar, gestionar y mantener clústeres de Kubernetes con Amazon EKS, escalando de forma óptima con **EKS Auto Mode** y los objetos de **Karpenter**.

> [!IMPORTANT]
> Si ejecutas este workshop fuera de un evento oficial de AWS, incurrirás en costos. Recuerda completar la sección de **Limpieza** al finalizar.

---

## Descripción general

En este workshop aprenderás a aprovisionar y escalar nodos de forma automática usando EKS Auto Mode, cuyo aprovisionamiento se apoya en objetos de Karpenter. Karpenter observa los pods pendientes y lanza instancias Amazon EC2 del tamaño adecuado según los requisitos de tus cargas de trabajo. La selección de instancias se basa en la intención: resource requests y restricciones de scheduling de Kubernetes.

Se despliega un clúster de Amazon EKS con EKS Auto Mode habilitado. Karpenter se usa para aprovisionar una mezcla de instancias **On-Demand** y **Amazon EC2 Spot**, mostrando los beneficios de un autoescalador *group-less* (sin grupos de nodos).

Este workshop está basado en el [Amazon EKS Workshop](https://www.eksworkshop.com/) y se enfoca en crear clústeres eficientes mediante Karpenter y buenas prácticas de cómputo eficiente.

### Audiencia objetivo

No se cubre la introducción a Amazon EKS. Se espera que conozcas:

- Conceptos básicos de Kubernetes
- Horizontal Pod Autoscaler (HPA)
- Cluster Autoscaler

### Datos del workshop

| Campo | Valor |
|-------|-------|
| Duración estimada | 2 horas |
| Región de ejemplo | `eu-west-1` / `us-east-2` (según el evento) |
| Nombre del clúster | `karpenter-workshop` |
| Entorno | VS Code Server en el navegador con acceso al clúster EKS |

---

## Índice del workshop

Cada sección vive en su propia carpeta dentro de [`docs/`](docs/).

| # | Sección | Documento |
|---|---------|-----------|
| 00 | Introducción | [`docs/00-introduccion/`](docs/00-introduccion/README.md) |
| 01 | Inicio del workshop · Probar el clúster | [`docs/01-inicio-del-workshop/`](docs/01-inicio-del-workshop/README.md) |
| 02 | Herramientas de visualización del clúster | [`docs/02-visualizacion-del-cluster/`](docs/02-visualizacion-del-cluster/README.md) |
| 03 | EKS Auto Mode | [`docs/03-eks-auto-mode/`](docs/03-eks-auto-mode/README.md) |
| 04 | Karpenter | [`docs/04-karpenter/`](docs/04-karpenter/README.md) |
| 05 | Escalado de aplicación y clúster | [`docs/05-escalado/`](docs/05-escalado/README.md) |
| 06 | Conclusión | [`docs/06-conclusion/`](docs/06-conclusion/README.md) |
| 07 | Limpieza | [`docs/07-limpieza/`](docs/07-limpieza/README.md) |
| 08 | Recursos y lecturas adicionales | [`docs/08-recursos/`](docs/08-recursos/README.md) |

Material complementario:

- **Guía de referencia de configuración** (campo por campo): [`docs/guia-referencia/`](docs/guia-referencia/README.md)
- **Plantillas de despliegue** (Spot amplio / On-Demand justo, por entorno, GPU): [`templates/`](templates/README.md)
- **Manifiestos reutilizables** del workshop: [`manifests/`](manifests/)

---

## Estructura del repositorio

```
aws-carpenter/
├── README.md                     # Este índice
├── docs/
│   ├── 00-introduccion/
│   ├── 01-inicio-del-workshop/
│   ├── 02-visualizacion-del-cluster/
│   ├── 03-eks-auto-mode/
│   ├── 04-karpenter/
│   │   ├── README.md
│   │   ├── 01-nodepool-personalizado.md
│   │   ├── 02-aprovisionamiento-automatico.md
│   │   ├── 03-consolidacion.md
│   │   ├── 04-spot.md
│   │   └── 05-consolidacion-spot-a-spot.md
│   ├── 05-escalado/
│   ├── 06-conclusion/
│   ├── 07-limpieza/
│   └── 08-recursos/
└── manifests/
    ├── nodepool-custom-spot.yaml
    ├── nodepool-custom-ondemand.yaml
    ├── nodepool-spot-constrained.yaml
    ├── inflate.yaml
    └── inflate-spot.yaml
```

---

## Convenciones

- Todos los comandos están pensados para ejecutarse en la terminal de VS Code Server del entorno del workshop.
- Pegar comandos en la terminal: `Shift+V` (Windows/Linux) o `Cmd+Shift+V` (macOS).
- Se recomienda usar una terminal dividida: una para `kubectl` y otra para `eks-node-viewer`.

---

> © 2008 - 2026, Amazon Web Services, Inc. o sus afiliados. Documentación traducida y reorganizada en español con fines de referencia del workshop.
