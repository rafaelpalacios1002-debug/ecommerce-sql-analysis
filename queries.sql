-- ==========================================================
-- Consultas de análisis: Ventas E-commerce
-- Nivel: Intermedio (CTEs, Window Functions, Subqueries)
-- Motor objetivo: PostgreSQL (compatible con la mayoría con
-- ajustes menores en funciones de fecha)
-- ==========================================================


-- ----------------------------------------------------------
-- 1. INGRESOS MENSUALES CON ACUMULADO (Window Function)
--    Usa SUM() OVER() para calcular el running total mes a mes
-- ----------------------------------------------------------
WITH ingresos_mensuales AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS mes,
        SUM(oi.quantity * oi.unit_price) AS ingresos
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'completado'
    GROUP BY 1
)
SELECT
    mes,
    ingresos,
    SUM(ingresos) OVER (ORDER BY mes) AS ingresos_acumulados,
    ROUND(
        (ingresos - LAG(ingresos) OVER (ORDER BY mes))
        / NULLIF(LAG(ingresos) OVER (ORDER BY mes), 0) * 100, 1
    ) AS crecimiento_pct_mensual
FROM ingresos_mensuales
ORDER BY mes;


-- ----------------------------------------------------------
-- 2. TOP 3 PRODUCTOS MÁS VENDIDOS POR CATEGORÍA
--    Usa RANK() para rankear dentro de cada categoría
-- ----------------------------------------------------------
WITH ventas_producto AS (
    SELECT
        c.category_name,
        p.product_name,
        SUM(oi.quantity) AS unidades_vendidas,
        SUM(oi.quantity * oi.unit_price) AS ingresos_totales
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    JOIN categories c ON c.category_id = p.category_id
    WHERE o.status = 'completado'
    GROUP BY c.category_name, p.product_name
),
ranking AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY category_name ORDER BY unidades_vendidas DESC) AS ranking_categoria
    FROM ventas_producto
)
SELECT category_name, product_name, unidades_vendidas, ingresos_totales, ranking_categoria
FROM ranking
WHERE ranking_categoria <= 3
ORDER BY category_name, ranking_categoria;


-- ----------------------------------------------------------
-- 3. SEGMENTACIÓN DE CLIENTES ESTILO RFM SIMPLIFICADO
--    (Recencia, Frecuencia, Valor Monetario) usando CTEs
-- ----------------------------------------------------------
WITH gasto_cliente AS (
    SELECT
        cu.customer_id,
        cu.customer_name,
        COUNT(DISTINCT o.order_id) AS frecuencia_pedidos,
        SUM(oi.quantity * oi.unit_price) AS valor_monetario,
        MAX(o.order_date) AS ultima_compra
    FROM customers cu
    JOIN orders o ON o.customer_id = cu.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'completado'
    GROUP BY cu.customer_id, cu.customer_name
),
segmentado AS (
    SELECT
        *,
        NTILE(3) OVER (ORDER BY valor_monetario DESC) AS tercio_valor,
        CURRENT_DATE - ultima_compra AS dias_desde_ultima_compra
    FROM gasto_cliente
)
SELECT
    customer_name,
    frecuencia_pedidos,
    valor_monetario,
    dias_desde_ultima_compra,
    CASE tercio_valor
        WHEN 1 THEN 'Alto valor'
        WHEN 2 THEN 'Valor medio'
        ELSE 'Bajo valor'
    END AS segmento
FROM segmentado
ORDER BY valor_monetario DESC;


-- ----------------------------------------------------------
-- 4. CLIENTES CON TICKET PROMEDIO SUPERIOR AL PROMEDIO GENERAL
--    Subquery correlacionada + subquery escalar
-- ----------------------------------------------------------
SELECT
    cu.customer_name,
    ROUND(AVG(oi.quantity * oi.unit_price), 2) AS ticket_promedio_producto
FROM customers cu
JOIN orders o ON o.customer_id = cu.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completado'
GROUP BY cu.customer_name
HAVING AVG(oi.quantity * oi.unit_price) > (
    SELECT AVG(oi2.quantity * oi2.unit_price)
    FROM order_items oi2
    JOIN orders o2 ON o2.order_id = oi2.order_id
    WHERE o2.status = 'completado'
)
ORDER BY ticket_promedio_producto DESC;


-- ----------------------------------------------------------
-- 5. TASA DE CLIENTES RECURRENTES (Repeat Purchase Rate)
-- ----------------------------------------------------------
WITH pedidos_por_cliente AS (
    SELECT customer_id, COUNT(*) AS n_pedidos
    FROM orders
    WHERE status = 'completado'
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE n_pedidos > 1) AS clientes_recurrentes,
    COUNT(*) AS total_clientes_con_pedido,
    ROUND(
        COUNT(*) FILTER (WHERE n_pedidos > 1)::numeric / COUNT(*) * 100, 1
    ) AS tasa_recurrencia_pct
FROM pedidos_por_cliente;


-- ----------------------------------------------------------
-- 6. MARGEN DE GANANCIA POR CATEGORÍA
--    Compara precio de venta vs costo
-- ----------------------------------------------------------
SELECT
    c.category_name,
    SUM(oi.quantity * oi.unit_price) AS ingresos,
    SUM(oi.quantity * p.cost) AS costo_total,
    SUM(oi.quantity * (oi.unit_price - p.cost)) AS margen_bruto,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - p.cost))
        / NULLIF(SUM(oi.quantity * oi.unit_price), 0) * 100, 1
    ) AS margen_pct
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
WHERE o.status = 'completado'
GROUP BY c.category_name
ORDER BY margen_bruto DESC;


-- ----------------------------------------------------------
-- 7. DÍAS PROMEDIO ENTRE PEDIDOS POR CLIENTE (Window Function LAG)
--    Útil para entender la frecuencia de recompra
-- ----------------------------------------------------------
WITH pedidos_ordenados AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS pedido_anterior
    FROM orders
    WHERE status = 'completado'
)
SELECT
    customer_id,
    ROUND(AVG(order_date - pedido_anterior), 1) AS dias_promedio_entre_pedidos
FROM pedidos_ordenados
WHERE pedido_anterior IS NOT NULL
GROUP BY customer_id
ORDER BY dias_promedio_entre_pedidos ASC;
