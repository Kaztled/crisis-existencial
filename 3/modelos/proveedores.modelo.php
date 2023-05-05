<?php 
require_once "conexion.php";

class ProveedoresModelo{
    
    static public function mdlListarProveedores(){
        
        $stmt = Conexion::conectar()->prepare("SELECT  id,ruc,razon_social,direccion 
                                                FROM proveedores order by id DESC");
        $stmt->execute();
        return $stmt->fetchAll();
    }
}
