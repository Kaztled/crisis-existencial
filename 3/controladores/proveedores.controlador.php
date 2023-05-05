<?php 
class clientesControlador{
static public function ctrListarclientes(){
    
    $clientes=clientesModelo::mdlListarclientes();
    return $clientes;
}



}