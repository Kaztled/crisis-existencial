<?php 
require_once "../controladores/clientes.controlador.php";
require_once "../modelos/clientes.modelo.php";

class ajaxclientes{
    public function ajaxListarclientes(){
   $clientes = clientesControlador::ctrListarclientes();
   echo json_encode($clientes, JSON_UNESCAPED_UNICODE);
    }
}

$listaclientes= new ajaxclientes();
$listaclientes -> ajaxListarclientes();
