<?php

class ReporteControlador{

    static public function ctrGetDatosReporte($start_date, $end_date){

        $datos = ReporteModelo::mdlGetDatosReportes($start_date, $end_date);

        return $datos;
    }
}
