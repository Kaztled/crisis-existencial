<?php
// Include the conexion.php file to connect to the database
require_once 'D:\xampp\htdocs\crisis existencial\3\modelos\conexion.php';

// Get the date range values from the POST data
$fechaInicio = $_POST['fecha_inicio'];
$fechaFin = $_POST['fecha_fin'];

// Query to get the report data
$query = "SELECT p.codigo_producto, p.descripcion_producto, p.stock_producto, SUM(vd.cantidad) AS cantidad_vendida, SUM(vd.total_venta) AS total_ventas FROM productos p INNER JOIN venta_detalle vd ON p.codigo_producto = vd.codigo_producto WHERE vd.fecha_venta BETWEEN ? AND ? GROUP BY p.codigo_producto";

// Prepare and execute the query
$stmt = $db->prepare($query);
$stmt->bind_param('ss', $fechaInicio, $fechaFin);
$stmt->execute();
$result = $stmt->get_result();

// Generate the report table
echo "<table>";
echo "<tr><th>Product Code</th><th>Description</th><th>Stock</th><th>Quantity Sold</th><th>Total Sales</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    echo "<td>" . $row['codigo_producto'] . "</td>";
    echo "<td>" . $row['descripcion_producto'] . "</td>";
    echo "<td>" . $row['stock_producto'] . "</td>";
    echo "<td>" . $row['cantidad_vendida'] . "</td>";
    echo "<td>" . $row['total_ventas'] . "</td>";
    echo "</tr>";
}
echo "</table>";
?>