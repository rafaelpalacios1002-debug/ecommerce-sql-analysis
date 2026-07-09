# 📊 Análisis de Ventas E-commerce con SQL

Proyecto de portafolio que simula una base de datos de una tienda online y aplica consultas SQL de nivel intermedio para extraer insights de negocio: tendencias de ingresos, segmentación de clientes, productos top y márgenes de ganancia.

## 🧱 Estructura de la base de datos

El modelo relacional cuenta con 5 tablas:

```
categories ──┐
             ├──> products ──┐
customers ───┤               ├──> order_items
             └──> orders ────┘
```

- **categories** — categorías de productos (Electrónica, Ropa, Hogar, etc.)
- **customers** — clientes con ciudad, país y fecha de registro
- **products** — catálogo con precio y costo (para calcular márgenes)
- **orders** — pedidos con fecha y estado (completado / cancelado / pendiente)
- **order_items** — detalle de cada pedido (línea por producto)

## 📁 Archivos del proyecto

| Archivo         | Descripción                                              |
|------------------|-----------------------------------------------------------|
| `schema.sql`     | Definición de tablas, llaves foráneas e índices           |
| `seed_data.sql`  | Datos de ejemplo: 20 clientes, 19 productos, 150 pedidos, 374 líneas de detalle (enero–junio 2025) |
| `queries.sql`    | 7 consultas de análisis comentadas                        |

## 🔍 Consultas incluidas

1. **Ingresos mensuales con acumulado** — `SUM() OVER()`, `LAG()`
2. **Top 3 productos por categoría** — `RANK() OVER (PARTITION BY ...)`
3. **Segmentación de clientes (RFM simplificado)** — CTEs + `NTILE()`
4. **Clientes con ticket promedio superior a la media** — subquery correlacionada
5. **Tasa de clientes recurrentes** — `COUNT(*) FILTER (WHERE ...)`
6. **Margen de ganancia por categoría** — agregaciones con joins múltiples
7. **Días promedio entre pedidos por cliente** — `LAG()` sobre fechas

Cada consulta está pensada para responder una pregunta de negocio concreta, no solo para mostrar sintaxis.

## ▶️ Cómo ejecutar el proyecto

Compatible con **PostgreSQL** (usa `NTILE`, `FILTER`, `DATE_TRUNC`). Con psql:

```bash
createdb ecommerce_analysis
psql -d ecommerce_analysis -f schema.sql
psql -d ecommerce_analysis -f seed_data.sql
psql -d ecommerce_analysis -f queries.sql
```

> Nota: para MySQL o SQLite, reemplaza `NTILE`/`FILTER`/`DATE_TRUNC` por sus equivalentes (`ROW_NUMBER` con buckets manuales, `SUM(CASE WHEN...)`, `strftime`, respectivamente).

## 💡 Ejemplos de insights que se pueden extraer

- ¿Qué mes tuvo el mayor crecimiento de ingresos respecto al anterior?
- ¿Qué categoría genera más margen bruto, no solo más ingresos?
- ¿Qué porcentaje de clientes vuelve a comprar (recurrencia)?
- ¿Qué clientes gastan más por compra y merecen atención VIP?

## 🛠️ Habilidades demostradas

- Modelado relacional y normalización
- Joins múltiples entre tablas
- Common Table Expressions (CTEs)
- Window functions (`RANK`, `NTILE`, `LAG`, `SUM() OVER()`)
- Subqueries correlacionadas y escalares
- Agregaciones condicionales

---

*Datos sintéticos generados para fines demostrativos — no representan una empresa real.*
