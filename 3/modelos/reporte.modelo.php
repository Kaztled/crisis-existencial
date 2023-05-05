<?php

require_once "conexion.php";

class ReporteModelo{

    static public function mdlGetDatosReportes($start_date, $end_date){

        $stmt = Conexion::conectar()->prepare('CALL GetTotalSales(:start_date, :end_date)');

        $stmt->bindParam(':start_date', $start_date, PDO::PARAM_STR);
        $stmt->bindParam(':end_date', $end_date, PDO::PARAM_STR);

        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_OBJ);
    }
}
