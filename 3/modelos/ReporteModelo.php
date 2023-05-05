<?php
class ReporteModelo {
    private $db;

    public function __construct() {
        require_once 'D:\xampp\htdocs\crisis existencial\3\modelos\conexion.php';
        $this->db = Conexion::conectar();
    }

    public function obtenerReporte($fechaInicio, $fechaFin) {
        $stmt = $this->db->prepare('SELECT p.codigo_producto, p.descripcion_producto, p.stock_producto, SUM(vd.cantidad) AS total_ventas FROM productos p LEFT JOIN venta_detalle vd ON p.codigo_producto = vd.codigo_producto WHERE vd.fecha_venta BETWEEN :fechaInicio AND :fechaFin GROUP BY p.codigo_producto');
        $stmt->bindParam(':fechaInicio', $fechaInicio);
        $stmt->bindParam(':fechaFin', $fechaFin);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}