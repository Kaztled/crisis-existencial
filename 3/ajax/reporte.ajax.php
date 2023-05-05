<?php

require_once "../controladores/reporte.controlador.php";
require_once "../modelos/reporte.modelo.php";

class AjaxReporte{

    public function getDatosReporte(){

        $start_date = $_POST['start_date'];
        $end_date = $_POST['end_date'];

        $datos = ReporteControlador::ctrGetDatosReporte($start_date, $end_date);

        echo json_encode($datos);
    }

}

$reporteAjax = new AjaxReporte();
$reporteAjax->getDatosReporte();

