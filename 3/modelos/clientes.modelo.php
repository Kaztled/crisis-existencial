<?php 
require_once "conexion.php";

class clientesModelo{
    
    static public function mdlListarClientes(){

        $stmt = Conexion::conectar()->prepare("SELECT  id_cliente, 
                                                        nombre, 
                                                        calle, 
                                                        colonia,
                                                        num_Interior,
                                                        num_Exterior,
                                                        codigo_Postal,
                                                        ciudad,
                                                        estado,
                                                        tipo_Persona,
                                                        RFC
                                                FROM clientes  order BY id_cliente DESC"); 
                                                 
        $stmt -> execute();
    
        return $stmt->fetchAll();
    }
    }    