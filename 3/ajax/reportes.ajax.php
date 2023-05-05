<?php
// Include the conexion.php file to connect to the database
require_once 'D:\xampp\htdocs\crisis existencial\3\modelos\conexion.php';

// Get the form values from the POST data
$start_date = $_POST['start_date'];
$end_date = $_POST['end_date'];
$product_code = $_POST['product_code'];

// Query to get the report data
$query = "SELECT p.codigo_producto, p.descripcion_producto, p.stock_producto, SUM(vd.total_venta) AS total_ventas FROM productos p INNER JOIN venta_detalle vd ON p.codigo_producto = vd.codigo_producto WHERE vd.fecha_venta BETWEEN ? AND ? AND p.codigo_producto = ? GROUP BY p.codigo_producto";

// Prepare and execute the query
$stmt = $db->prepare($query);
$stmt->bind_param('sss', $start_date, $end_date, $product_code);
$stmt->execute();
$result = $stmt->get_result();

// Generate the report data
$report_data = array();
while ($row = $result->fetch_assoc()) {
    $report_data[] = array(
        $row['codigo_producto'],
        $row['descripcion_producto'],
        $row['stock_producto'],
        $row['total_ventas']
    );
}

// Return the report data as a JSON array
echo json_encode($report_data);

// Close the database connection
$db->close();
?>