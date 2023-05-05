-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 03-05-2023 a las 04:09:54
-- Versión del servidor: 10.4.24-MariaDB
-- Versión de PHP: 8.1.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bodega`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetTotalSales` (IN `start_date` DATE, IN `end_date` DATE)   BEGIN
    SELECT
        p.codigo_producto,
        p.descripcion_producto,
        p.precio_venta_producto,
        SUM(ROUND(vd.total_venta)) AS total_ventas
    FROM
        productos p
        INNER JOIN venta_detalle vd ON p.codigo_producto = vd.codigo_producto
    WHERE
        vd.fecha_venta BETWEEN start_date AND end_date
    GROUP BY
        p.codigo_producto,
        p.descripcion_producto,
        p.precio_venta_producto
    ORDER BY
        total_ventas DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ActualizarDetalleVenta` (IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_id` INT)   BEGIN

 declare v_nro_boleta varchar(20);
 declare v_total_venta float;

/*
ACTUALIZAR EL STOCK DEL PRODUCTO QUE SEA MODIFICADO
......
.....
.......
*/

/*
ACTULIZAR CODIGO, CANTIDAD Y TOTAL DEL ITEM MODIFICADO
*/

 UPDATE venta_detalle 
 SET codigo_producto = p_codigo_producto, 
 cantidad = p_cantidad, 
 total_venta = (p_cantidad * (select precio_venta_producto from productos where codigo_producto = p_codigo_producto))
 WHERE id = p_id;
 
 set v_nro_boleta = (select nro_boleta from venta_detalle where id = p_id);
 set v_total_venta = (select sum(total_venta) from venta_detalle where nro_boleta = v_nro_boleta);
 
 update venta_cabecera
   set total_venta = v_total_venta
 where nro_boleta = v_nro_boleta;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_eliminar_venta` (IN `p_nro_boleta` VARCHAR(8))   BEGIN

DECLARE v_codigo VARCHAR(20);
DECLARE v_cantidad FLOAT;
DECLARE done INT DEFAULT FALSE;

DECLARE cursor_i CURSOR FOR 
SELECT codigo_producto,cantidad 
FROM venta_detalle 
where CAST(nro_boleta AS CHAR CHARACTER SET utf8)  = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

OPEN cursor_i;
read_loop: LOOP
FETCH cursor_i INTO v_codigo, v_cantidad;

	IF done THEN
	  LEAVE read_loop;
	END IF;
    
    UPDATE PRODUCTOS 
       SET stock_producto = stock_producto + v_cantidad
    WHERE CAST(codigo_producto AS CHAR CHARACTER SET utf8) = CAST(v_codigo AS CHAR CHARACTER SET utf8);
    
END LOOP;
CLOSE cursor_i;

DELETE FROM VENTA_DETALLE WHERE CAST(nro_boleta AS CHAR CHARACTER SET utf8) = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;
DELETE FROM VENTA_CABECERA WHERE CAST(nro_boleta AS CHAR CHARACTER SET utf8)  = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;

SELECT 'Se eliminó correctamente la venta';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarCategorias` ()   BEGIN
select * from categorias;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductos` ()   SELECT   '' as detalles,
		codigo_producto,
		id_categoria_producto,
		nombre_categoria,
		descripcion_producto,
		ROUND(precio_compra_producto,2) as precio_compra_producto,
		ROUND(precio_venta_producto,2) as precio_venta_producto,
        ROUND(precio_mayor_producto,2) as precio_mayor_producto,
        ROUND(precio_oferta_producto,2) as precio_oferta_producto,
		case when c.aplica_peso = 1 then concat(stock_producto,' M')
			else concat(stock_producto,' Und(s)') end as stock_producto,
		case when c.aplica_peso = 1 then concat(minimo_stock_producto,' M')
			else concat(minimo_stock_producto,' Und(s)') end as minimo_stock_producto,
		case when c.aplica_peso = 1 then concat(ventas_producto,' M') 
			else concat(ventas_producto,' Und(s)') end as ventas_producto,
		ROUND(costo_total_producto,2) as costo_total_producto,
		fecha_creacion_producto,
		fecha_actualizacion_producto,
		'' as acciones
	FROM productos p INNER JOIN categorias c on p.id_categoria_producto = c.id_categoria 
	order by p.codigo_producto desc$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosMasVendidos` ()  NO SQL BEGIN

select  p.codigo_producto,
		p.descripcion_producto,
        sum(vd.cantidad) as cantidad,
        sum(Round(vd.total_venta,2)) as total_venta
from venta_detalle vd inner join productos p on vd.codigo_producto = p.codigo_producto
group by p.codigo_producto,
		p.descripcion_producto
order by  sum(Round(vd.total_venta,2)) DESC
limit 10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosPocoStock` ()  NO SQL BEGIN
select p.codigo_producto,
		p.descripcion_producto,
        p.stock_producto,
        p.minimo_stock_producto
from productos p
where p.stock_producto <= p.minimo_stock_producto
order by p.stock_producto asc;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProovedores` ()   SELECT '' as detalles,
       ID,
       RUC,
       RAZON_SOCIAL,
       DIRECCION,
       '' as acciones
FROM Proveedores
ORDER BY ID DESC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProveedores` ()   BEGIN
   SELECT *
   FROM Proveedores;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerDatosDashboard` ()  NO SQL BEGIN
  DECLARE totalProductos int;
  DECLARE totalCompras float;
  DECLARE totalVentas float;
  DECLARE ganancias float;
  DECLARE productosPocoStock int;
  DECLARE ventasHoy float;

  SET totalProductos = (SELECT
      COUNT(*)
    FROM productos p);
  SET totalCompras = (SELECT
      SUM(p.costo_total_producto)
    FROM productos p);
  /*set totalVentas = (select sum(vc.total_venta) from venta_cabecera vc where EXTRACT(MONTH FROM vc.fecha_venta) = EXTRACT(MONTH FROM curdate()) and EXTRACT(YEAR FROM vc.fecha_venta) = EXTRACT(YEAR FROM curdate()));*/
  SET totalVentas = (SELECT
      SUM(vc.total_venta)
    FROM venta_cabecera vc);
  /*set ganancias = (select sum(vd.total_venta - (p.precio_compra_producto * vd.cantidad)) 
  					from venta_detalle vd inner join productos p on vd.codigo_producto = p.codigo_producto
                   where EXTRACT(MONTH FROM vd.fecha_venta) = EXTRACT(MONTH FROM curdate()) 
                   and EXTRACT(YEAR FROM vd.fecha_venta) = EXTRACT(YEAR FROM curdate()));*/
  SET ganancias = (SELECT
      SUM(vd.cantidad * vd.precio_unitario_venta) - SUM(vd.cantidad * vd.costo_unitario_venta)
    FROM venta_detalle VD);
  SET productosPocoStock = (SELECT
      COUNT(1)
    FROM productos p
    WHERE p.stock_producto <= p.minimo_stock_producto);
  SET ventasHoy = (SELECT
      SUM(vc.total_venta)
    FROM venta_cabecera vc
    WHERE DATE(vc.fecha_venta) = CURDATE());

  SELECT
    IFNULL(totalProductos, 0) AS totalProductos,
    IFNULL(CONCAT(' ', FORMAT(totalCompras, 2)), 0) AS totalCompras,
    IFNULL(CONCAT(' ', FORMAT(totalVentas, 2)), 0) AS totalVentas,
    IFNULL(CONCAT(' ', FORMAT(ganancias, 2)), 0) AS ganancias,
    IFNULL(productosPocoStock, 0) AS productosPocoStock,
    IFNULL(CONCAT(' ', FORMAT(ventasHoy, 2)), 0) AS ventasHoy;



END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_obtenerNroBoleta` ()  NO SQL select serie_boleta,
		IFNULL(LPAD(max(c.nro_correlativo_venta)+1,8,'0'),'00000001') nro_venta 
from empresa c$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerVentasMesActual` ()  NO SQL BEGIN
SELECT date(vc.fecha_venta) as fecha_venta,
		sum(round(vc.total_venta,2)) as total_venta,
        (SELECT sum(round(vc1.total_venta,2))
			FROM venta_cabecera vc1
		where date(vc1.fecha_venta) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
		and date(vc1.fecha_venta) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
        and date(vc1.fecha_venta) = DATE_ADD(vc.fecha_venta, INTERVAL -1 MONTH)
		group by date(vc1.fecha_venta)) as total_venta_ant
FROM venta_cabecera vc
where date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 1 month) + INTERVAL 1 day)
and date(vc.fecha_venta) <= last_day(date(CURRENT_DATE))
group by date(vc.fecha_venta);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerVentasMesAnterior` ()  NO SQL BEGIN
SELECT date(vc.fecha_venta) as fecha_venta,
		sum(round(vc.total_venta,2)) as total_venta,
        sum(round(vc.total_venta,2)) as total_venta_ant
FROM venta_cabecera vc
where date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
and date(vc.fecha_venta) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
group by date(vc.fecha_venta);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_bono` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/
    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = p_nuevo_stock;
    SET v_costo_unitario_in = 0;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_in,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock_producto = v_unidades_ex, 
        precio_compra_producto = v_costo_unitario_ex,
        costo_total_producto = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_existencias` (IN `p_codigo_producto` VARCHAR(25), IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT, IN `p_costo_unitario` FLOAT, IN `p_costo_total` FLOAT)   BEGIN
  INSERT INTO KARDEX (codigo_producto, fecha, concepto, comprobante, ex_unidades, ex_costo_unitario, ex_costo_total)
    VALUES (p_codigo_producto, CURDATE(), p_concepto, p_comprobante, p_unidades, p_costo_unitario, p_costo_total);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_vencido` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = p_nuevo_stock;
    SET v_costo_unitario_out = 0;
    SET v_costo_total_out = v_unidades_out * v_costo_unitario_out;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_out,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex - v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock_producto = v_unidades_ex, 
        precio_compra_producto = v_costo_unitario_ex,
        costo_total_producto = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_venta` (IN `p_codigo_producto` VARCHAR(20), IN `p_fecha` DATE, IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    

	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/
    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = p_unidades;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = p_unidades * v_costo_unitario_ex;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_ex - v_unidades_out,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex -  v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						p_fecha,
                        p_concepto,
                        p_comprobante,
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock_producto = v_unidades_ex, 
		ventas_producto = ventas_producto + v_unidades_out,
        precio_compra_producto = v_costo_unitario_ex,
        costo_total_producto = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_venta_detalle` (IN `p_nro_boleta` VARCHAR(8), IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_total_venta` FLOAT)   BEGIN
declare v_precio_compra float;
declare v_precio_venta float;

SELECT p.precio_compra_producto,p.precio_venta_producto
into v_precio_compra, v_precio_venta
FROM productos p
WHERE p.codigo_producto  = p_codigo_producto;
    
INSERT INTO venta_detalle(nro_boleta,codigo_producto, cantidad, costo_unitario_venta,precio_unitario_venta,total_venta, fecha_venta) 
VALUES(p_nro_boleta,p_codigo_producto,p_cantidad, v_precio_compra, v_precio_venta,p_total_venta,curdate());
                                                        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_top_ventas_categorias` ()   BEGIN

select cast(sum(vd.total_venta)  AS DECIMAL(8,2)) as y, c.nombre_categoria as label
    from venta_detalle vd inner join productos p on vd.codigo_producto = p.codigo_producto
                        inner join categorias c on c.id_categoria = p.id_categoria_producto
    group by c.nombre_categoria
    LIMIT 10;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `arqueo_caja`
--

CREATE TABLE `arqueo_caja` (
  `id` int(11) NOT NULL,
  `id_caja` int(11) DEFAULT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `fecha_inicio` datetime DEFAULT NULL,
  `fecha_fin` datetime DEFAULT NULL,
  `monto_inicial` float DEFAULT NULL,
  `ingresos` float DEFAULT NULL,
  `devoluciones` float DEFAULT NULL,
  `gastos` float DEFAULT NULL,
  `monto_final` float DEFAULT NULL,
  `status` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cajas`
--

CREATE TABLE `cajas` (
  `id` int(11) NOT NULL,
  `numero_caja` int(11) NOT NULL,
  `nombre_caja` varchar(100) NOT NULL,
  `estado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id_categoria` int(11) NOT NULL,
  `nombre_categoria` text COLLATE utf8_spanish_ci DEFAULT NULL,
  `aplica_peso` int(11) NOT NULL,
  `fecha_creacion_categoria` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion_categoria` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id_categoria`, `nombre_categoria`, `aplica_peso`, `fecha_creacion_categoria`, `fecha_actualizacion_categoria`) VALUES
(4189, 'Frutas', 1, '2023-04-17 03:08:52', '2023-04-17'),
(4190, 'Verduras', 1, '2023-04-17 03:08:52', '2023-04-17'),
(4191, 'Snack', 0, '2023-04-17 03:08:52', '2023-04-17'),
(4192, 'Avena', 0, '2023-04-17 03:08:52', '2023-04-17'),
(4193, 'Energizante', 0, '2023-04-17 03:08:52', '2023-04-17'),
(4194, 'Jugo', 0, '2023-04-17 03:08:52', '2023-04-17'),
(4195, 'Refresco', 0, '2023-04-17 03:08:52', '2023-04-17'),
(4196, 'Mantequilla', 0, '2023-04-17 03:08:53', '2023-04-17'),
(4197, 'Gaseosa', 0, '2023-04-17 03:08:53', '2023-04-17'),
(4198, 'Aceite', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4199, 'Yogurt', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4200, 'Arroz', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4201, 'Leche', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4202, 'Papel Higiénico', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4203, 'Atún', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4204, 'Chocolate', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4205, 'Wafer', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4206, 'Golosina', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4207, 'Galletas', 0, '2023-04-17 03:08:54', '2023-04-17'),
(4208, 'Cable', 1, '2023-04-17 03:08:54', '2023-04-17');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id_Cliente` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `calle` varchar(50) NOT NULL,
  `colonia` varchar(50) NOT NULL,
  `num_Interior` varchar(10) NOT NULL,
  `num_Exterior` varchar(10) DEFAULT NULL,
  `codigo_Postal` varchar(5) NOT NULL,
  `ciudad` varchar(50) NOT NULL,
  `estado` varchar(50) NOT NULL,
  `tipo_Persona` int(11) NOT NULL,
  `RFC` varchar(13) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id_Cliente`, `nombre`, `calle`, `colonia`, `num_Interior`, `num_Exterior`, `codigo_Postal`, `ciudad`, `estado`, `tipo_Persona`, `RFC`) VALUES
(1, 'Juan Perez', 'Av. Juarez', 'Centro', '5', '102', '76000', 'Queretaro', 'Queretaro', 1, 'PE0123456789'),
(2, 'Maria Garcia', 'Calle 5', 'San Jose', 'B', '203', '45010', 'Zapopan', 'Jalisco', 1, 'PA9876543210'),
(3, 'Pedro Hernandez', 'Av. Reforma', 'Juarez', '2', '56', '06000', 'Ciudad de Mexico', 'Ciudad de Mexico', 1, 'PE0123456789'),
(4, 'Juanita Lopez', 'Calle 10', 'Centro', 'C', '30', '68000', 'Oaxaca', 'Oaxaca', 1, 'PE0123456789'),
(5, 'Carlos Ramirez', 'Av. Insurgentes', 'Del Valle', 'D', '103', '03100', 'Ciudad de Mexico', 'Ciudad de Mexico', 1, 'PE0123456789'),
(6, 'Grupo Industrial SA de CV', 'Av. Constitucion', 'Industrial', '', '500', '78395', 'San Luis Potosi', 'San Luis Potosi', 2, 'P987654321012'),
(7, 'Servicios Contables SA de CV', 'Calle 15', 'Norte', '10', '120', '58000', 'Morelia', 'Michoacan', 2, 'P987654321012'),
(8, 'Inmobiliaria San Agustin SA de CV', 'Av. Miguel Hidalgo', 'San Agustin', ' ', '140', '66260', 'Monterrey', 'Nuevo Leon', 2, 'P987654321012'),
(9, 'Consultoria Empresarial SA de CV', 'Av. Insurgentes', 'Napoles', '', '203', '03810', 'Ciudad de Mexico', 'Ciudad de Mexico', 2, 'P987654321012'),
(10, 'Constructora Goyco SA de CV', 'Calle 20', 'Linda Vista', '4', '50', '67130', 'Guadalupe', 'Nuevo Leon', 2, 'P987654321012');

--
-- Disparadores `clientes`
--
DELIMITER $$
CREATE TRIGGER `tr_actualizar_tipo_persona` BEFORE INSERT ON `clientes` FOR EACH ROW BEGIN
    DECLARE rfc_length INT;
    SET rfc_length = LENGTH(NEW.RFC);
    IF rfc_length < 13 THEN
        SET NEW.tipo_persona = 1;
    ELSE
        SET NEW.tipo_persona = 2;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id` int(11) NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `id_tipo_comprobante` varchar(3) DEFAULT NULL,
  `serie_comprobante` varchar(10) DEFAULT NULL,
  `nro_comprobante` varchar(20) DEFAULT NULL,
  `fecha_comprobante` datetime DEFAULT NULL,
  `id_moneda_comprobante` int(11) DEFAULT NULL,
  `ope_exonerada` float DEFAULT NULL,
  `ope_inafecta` float DEFAULT NULL,
  `ope_gravada` float DEFAULT NULL,
  `igv` float DEFAULT NULL,
  `total_compra` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `id` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `cantidad` float DEFAULT NULL,
  `costo_unitario` float DEFAULT NULL,
  `descuento` float DEFAULT NULL,
  `subtotal` float DEFAULT NULL,
  `impuesto` float DEFAULT NULL,
  `total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresa`
--

CREATE TABLE `empresa` (
  `id_empresa` int(11) NOT NULL,
  `razon_social` text NOT NULL,
  `ruc` bigint(20) NOT NULL,
  `direccion` text NOT NULL,
  `marca` text NOT NULL,
  `serie_boleta` varchar(4) NOT NULL,
  `nro_correlativo_venta` varchar(8) NOT NULL,
  `email` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `empresa`
--

INSERT INTO `empresa` (`id_empresa`, `razon_social`, `ruc`, `direccion`, `marca`, `serie_boleta`, `nro_correlativo_venta`, `email`) VALUES
(1, 'Maga & Tito Market', 10467291241, 'Avenida Brasil 1347 - Jesus María', 'Maga & Tito Market', 'B001', '00000265', 'magaytito@gmail.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `kardex`
--

CREATE TABLE `kardex` (
  `id` int(11) NOT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `concepto` varchar(100) DEFAULT NULL,
  `comprobante` varchar(50) DEFAULT NULL,
  `in_unidades` float DEFAULT NULL,
  `in_costo_unitario` float DEFAULT NULL,
  `in_costo_total` float DEFAULT NULL,
  `out_unidades` float DEFAULT NULL,
  `out_costo_unitario` float DEFAULT NULL,
  `out_costo_total` float DEFAULT NULL,
  `ex_unidades` float DEFAULT NULL,
  `ex_costo_unitario` float DEFAULT NULL,
  `ex_costo_total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `kardex`
--

INSERT INTO `kardex` (`id`, `codigo_producto`, `fecha`, `concepto`, `comprobante`, `in_unidades`, `in_costo_unitario`, `in_costo_total`, `out_unidades`, `out_costo_unitario`, `out_costo_total`, `ex_unidades`, `ex_costo_unitario`, `ex_costo_total`) VALUES
(8532, '1', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 5.9, 141.6),
(8533, '2', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 12.1, 278.3),
(8534, '3', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 12.4, 359.6),
(8535, '4', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.25, 84.5),
(8536, '5', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 5.15, 118.45),
(8537, '6', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 9.8, 284.2),
(8538, '7', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 7.49, 202.23),
(8539, '8', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 8, 208),
(8540, '9', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 10, 260),
(8541, '10', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.79, 79.59),
(8542, '11', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 3.99, 99.75),
(8543, '12', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 1.29, 34.83),
(8544, '13', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 1, 27),
(8545, '14', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 1.9, 47.5),
(8546, '15', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 2.8, 75.6),
(8547, '16', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 4.4, 88),
(8548, '17', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 3.79, 87.17),
(8549, '18', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.79, 98.54),
(8550, '19', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 3.65, 87.6),
(8551, '20', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 3.5, 70),
(8552, '21', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 3.17, 85.59),
(8553, '22', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 5.17, 155.1),
(8554, '23', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 4.58, 128.4),
(8555, '24', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5, 110),
(8556, '25', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 4.66, 125.82),
(8557, '26', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 4.65, 106.95),
(8558, '27', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 4.63, 97.23),
(8559, '28', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 5.7, 153.9),
(8560, '29', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 6.08, 164.16),
(8561, '30', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5.9, 129.8),
(8562, '31', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 5.9, 165.2),
(8563, '32', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.9, 171.1),
(8564, '33', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 5.08, 106.68),
(8565, '34', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.63, 163.27),
(8566, '35', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.9, 171.1),
(8567, '36', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 5.9, 159.3),
(8568, '37', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5.33, 117.26),
(8569, '38', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 8.9, 186.9),
(8570, '39', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 5.7, 119.7),
(8571, '40', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 18.29, 384.09),
(8572, '41', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 2.8, 78.4),
(8573, '42', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 1, 20),
(8574, '43', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.25, 68.25),
(8575, '44', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 3.1, 93),
(8576, '45', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.39, 71.19),
(8577, '46', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 1.3, 26),
(8578, '47', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 1.99, 55.72),
(8579, '48', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 1, 29),
(8580, '49', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 5.4, 124.2),
(8581, '50', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.53, 13.25),
(8582, '51', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 0.9, 20.7),
(8583, '52', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.9, 22),
(8584, '53', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 0.67, 20),
(8585, '54', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 1.39, 30),
(8586, '55', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 1.39, 41),
(8587, '56', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 1.39, 29),
(8588, '57', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 1.39, 34),
(8589, '58', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 2.8, 58),
(8590, '59', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 2.6, 57),
(8591, '60', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 2.6, 62),
(8592, '61', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 2.19, 53),
(8593, '62', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 2.19, 61),
(8594, '63', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 3.4, 85),
(8595, '64', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 0.5, 14),
(8596, '65', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.88, 21),
(8597, '66', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 1.5, 36),
(8598, '67', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.37, 11),
(8599, '68', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.68, 14),
(8600, '69', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.52, 12),
(8601, '70', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 0.52, 10),
(8602, '71', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 0.52, 11),
(8603, '72', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 0.47, 13),
(8604, '73', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.47, 11),
(8605, '74', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.47, 14),
(8606, '75', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.9, 26),
(8607, '76', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.62, 15),
(8608, '77', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.56, 12),
(8609, '78', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.5, 13),
(8610, '79', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 1.8, 50),
(8611, '80', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 3.69, 81),
(8612, '81', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 2.8, 76),
(8613, '82', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.33, 7),
(8614, '83', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 0.43, 9),
(8615, '84', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.75, 22),
(8616, '85', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 0.6, 17),
(8617, '86', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.85, 18),
(8618, '87', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 0.92, 24),
(8619, '88', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 1.06, 24),
(8620, '89', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 1.5, 31),
(8621, '90', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 1.5, 31.5),
(8622, '91', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 2.6, 59.8),
(8623, '92', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3, 63),
(8624, '93', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.2, 83.2),
(8625, '94', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 2.89, 72.25),
(8626, '95', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.57, 12),
(8627, '96', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.53, 11.66),
(8628, '97', '2023-04-16 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 100, 1, 100),
(8629, '97', '2023-04-18 00:00:00', 'VENTA', '00000258', NULL, NULL, NULL, 10, 1, 10, 90, 1, 90),
(8630, '9', '2023-04-18 00:00:00', 'VENTA', '00000259', NULL, NULL, NULL, 10, 10, 100, 16, 10, 160),
(8631, '57', '2023-04-18 00:00:00', 'VENTA', '00000260', NULL, NULL, NULL, 1, 1.39, 1.39, 24, 1.36, 32.61),
(8632, '4', '2023-04-18 00:00:00', 'VENTA', '00000261', NULL, NULL, NULL, 2, 3.25, 6.5, 24, 3.25, 78),
(8633, '9', '2023-04-18 00:00:00', 'VENTA', '00000261', NULL, NULL, NULL, 1, 10, 10, 15, 10, 150),
(8634, '4', '2023-04-18 00:00:00', 'VENTA', '00000262', NULL, NULL, NULL, 1, 3.25, 3.25, 23, 3.25, 74.75),
(8635, '42', '2023-04-25 00:00:00', 'VENTA', '00000263', NULL, NULL, NULL, 1, 1, 1, 19, 1, 19),
(8636, '80', '2023-04-25 00:00:00', 'VENTA', '00000264', NULL, NULL, NULL, 1, 3.69, 3.69, 21, 3.68, 77.31),
(8637, '3', '2023-04-25 00:00:00', 'VENTA', '00000264', NULL, NULL, NULL, 1, 12.4, 12.4, 28, 12.4, 347.2),
(8638, '41', '2023-04-25 00:00:00', 'VENTA', '00000264', NULL, NULL, NULL, 1, 2.8, 2.8, 27, 2.8, 75.6),
(8639, '10', '2023-04-25 00:00:00', 'VENTA', '00000264', NULL, NULL, NULL, 1, 3.79, 3.79, 20, 3.79, 75.8),
(8640, '55', '2023-04-25 00:00:00', 'VENTA', '00000264', NULL, NULL, NULL, 1, 1.39, 1.39, 29, 1.37, 39.61),
(8641, '97', '2023-04-25 00:00:00', 'VENTA', '00000264', NULL, NULL, NULL, 1, 1, 1, 89, 1, 89),
(8642, '37', '2023-04-25 00:00:00', 'VENTA', '00000264', NULL, NULL, NULL, 1, 5.33, 5.33, 21, 5.33, 111.93),
(8643, '1', '2023-04-25 00:00:00', 'VENTA', '00000265', NULL, NULL, NULL, 1, 5.9, 5.9, 23, 5.9, 135.7),
(8644, '2', '2023-04-25 00:00:00', 'VENTA', '00000265', NULL, NULL, NULL, 1, 12.1, 12.1, 22, 12.1, 266.2),
(8645, '4', '2023-04-25 00:00:00', 'VENTA', '00000265', NULL, NULL, NULL, 1, 3.25, 3.25, 22, 3.25, 71.5),
(8646, '40', '2023-04-25 00:00:00', 'VENTA', '00000265', NULL, NULL, NULL, 1, 18.29, 18.29, 20, 18.29, 365.8),
(8647, '16', '2023-04-25 00:00:00', 'VENTA', '00000265', NULL, NULL, NULL, 1, 4.4, 4.4, 19, 4.4, 83.6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modulos`
--

CREATE TABLE `modulos` (
  `id` int(11) NOT NULL,
  `modulo` varchar(45) DEFAULT NULL,
  `padre_id` int(11) DEFAULT NULL,
  `vista` varchar(45) DEFAULT NULL,
  `icon_menu` varchar(45) DEFAULT NULL,
  `orden` int(11) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `modulos`
--

INSERT INTO `modulos` (`id`, `modulo`, `padre_id`, `vista`, `icon_menu`, `orden`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'Tablero Principal', 0, 'dashboard.php', 'fas fa-tachometer-alt', 0, NULL, NULL),
(2, 'Ventas', 0, '', 'fas fa-store-alt', 1, NULL, NULL),
(3, 'Punto de Venta', 2, 'ventas.php', 'far fa-circle', 2, NULL, NULL),
(4, 'Administrar Ventas', 2, 'administrar_ventas.php', 'far fa-circle', 3, NULL, NULL),
(5, 'Productos', 0, NULL, 'fas fa-cart-plus', 4, NULL, NULL),
(6, 'Inventario', 5, 'productos.php', 'far fa-circle', 5, NULL, NULL),
(7, 'Carga Masiva', 5, 'carga_masiva_productos.php', 'far fa-circle', 6, NULL, NULL),
(8, 'Categorías', 5, 'categorias.php', 'far fa-circle', 7, NULL, NULL),
(9, 'Compras', 0, 'compras.php', 'fas fa-dolly', 9, NULL, NULL),
(10, 'Reportes', 0, 'reportes.php', 'fas fa-chart-line', 10, NULL, NULL),
(13, 'Roles y Perfiles', 0, 'modulos_perfiles.php', 'fas fa-tablet-alt', 13, NULL, NULL),
(16, 'Proovedores', 0, 'proovedores.php', 'fas fa-truck-moving', 14, '2023-04-18 09:01:32', NULL),
(18, 'Clientes', 0, 'clientes.php', 'fa fa-address-book', 15, '2023-04-26 03:53:19', NULL),
(19, 'Facturacion', 0, 'facturacion.php', 'fa fa-file-pdf-o', 16, '2023-04-26 05:34:43', NULL),
(20, 'Facturacion', 0, 'facturacion.php', 'fa fa-handshake-o', 16, '2023-04-26 05:34:43', NULL),
(21, 'Reporte de Stock', 0, 'reportestock.php', 'fa fa-window-maximize', 17, '2023-04-26 06:14:06', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `monedas`
--

CREATE TABLE `monedas` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfiles`
--

CREATE TABLE `perfiles` (
  `id_perfil` int(11) NOT NULL,
  `descripcion` varchar(45) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `perfiles`
--

INSERT INTO `perfiles` (`id_perfil`, `descripcion`, `estado`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'Administrador', 1, NULL, NULL),
(2, 'Vendedor', 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfil_modulo`
--

CREATE TABLE `perfil_modulo` (
  `idperfil_modulo` int(11) NOT NULL,
  `id_perfil` int(11) DEFAULT NULL,
  `id_modulo` int(11) DEFAULT NULL,
  `vista_inicio` tinyint(4) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `perfil_modulo`
--

INSERT INTO `perfil_modulo` (`idperfil_modulo`, `id_perfil`, `id_modulo`, `vista_inicio`, `estado`) VALUES
(13, 1, 13, NULL, 1),
(148, 2, 1, 1, 1),
(149, 2, 3, 0, 1),
(150, 2, 2, 0, 1),
(151, 2, 4, 0, 1),
(228, 1, 1, 1, 1),
(229, 1, 3, 0, 1),
(230, 1, 2, 0, 1),
(231, 1, 4, 0, 1),
(232, 1, 6, 0, 1),
(233, 1, 5, 0, 1),
(234, 1, 7, 0, 1),
(235, 1, 8, 0, 1),
(236, 1, 16, 0, 1),
(237, 1, 18, 0, 1),
(238, 1, 19, 0, 1),
(239, 1, 10, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `codigo_producto` varchar(20) CHARACTER SET utf8 NOT NULL,
  `id_categoria_producto` int(11) DEFAULT NULL,
  `descripcion_producto` text CHARACTER SET utf8 DEFAULT NULL,
  `precio_compra_producto` float NOT NULL,
  `precio_venta_producto` float NOT NULL,
  `precio_mayor_producto` float DEFAULT NULL,
  `precio_oferta_producto` float DEFAULT NULL,
  `stock_producto` float DEFAULT NULL,
  `minimo_stock_producto` float DEFAULT NULL,
  `ventas_producto` float DEFAULT NULL,
  `costo_total_producto` float DEFAULT NULL,
  `fecha_creacion_producto` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion_producto` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`codigo_producto`, `id_categoria_producto`, `descripcion_producto`, `precio_compra_producto`, `precio_venta_producto`, `precio_mayor_producto`, `precio_oferta_producto`, `stock_producto`, `minimo_stock_producto`, `ventas_producto`, `costo_total_producto`, `fecha_creacion_producto`, `fecha_actualizacion_producto`) VALUES
('1', 4199, 'test1', 5.9, 7.375, 7.08, 6.903, 23, 14, 1, 135.7, '2023-04-25 21:59:06', NULL),
('10', 4199, 'test10', 3.79, 4.7375, 4.548, 4.4343, 20, 11, 1, 75.8, '2023-04-25 21:46:20', NULL),
('11', 4202, 'test11', 3.99, 4.9875, 4.788, 4.6683, 25, 15, 0, 99.75, '2023-04-17 03:08:58', NULL),
('12', 4192, 'test12', 1.29, 1.6125, 1.548, 1.5093, 27, 17, 0, 34.83, '2023-04-17 03:08:58', NULL),
('13', 4194, 'test13', 1, 1.25, 1.2, 1.17, 27, 17, 0, 27, '2023-04-17 03:08:58', NULL),
('14', 4192, 'test14', 1.9, 2.375, 2.28, 2.223, 25, 15, 0, 47.5, '2023-04-17 03:08:58', NULL),
('15', 4201, 'test15', 2.8, 3.5, 3.36, 3.276, 27, 17, 0, 75.6, '2023-04-17 03:08:58', NULL),
('16', 4197, 'test16', 4.4, 5.5, 5.28, 5.148, 19, 10, 1, 83.6, '2023-04-25 21:59:08', NULL),
('17', 4199, 'test17', 3.79, 4.7375, 4.548, 4.4343, 23, 13, 0, 87.17, '2023-04-17 03:08:59', NULL),
('18', 4199, 'test18', 3.79, 4.7375, 4.548, 4.4343, 26, 16, 0, 98.54, '2023-04-17 03:08:59', NULL),
('19', 4199, 'test19', 3.65, 4.5625, 4.38, 4.2705, 24, 14, 0, 87.6, '2023-04-17 03:08:59', NULL),
('2', 4198, 'test2', 12.1, 15.125, 14.52, 14.157, 22, 13, 1, 266.2, '2023-04-25 21:59:07', NULL),
('20', 4197, 'test20', 3.5, 4.375, 4.2, 4.095, 20, 10, 0, 70, '2023-04-17 03:08:59', NULL),
('21', 4201, 'test21', 3.17, 3.9625, 3.804, 3.7089, 27, 17, 0, 85.59, '2023-04-17 03:09:00', NULL),
('22', 4203, 'test22', 5.17, 6.4625, 6.204, 6.0489, 30, 20, 0, 155.1, '2023-04-17 03:09:01', NULL),
('23', 4202, 'test23', 4.58, 5.725, 5.496, 5.3586, 28, 18, 0, 128.4, '2023-04-17 03:09:02', NULL),
('24', 4202, 'test24', 5, 6.25, 6, 5.85, 22, 12, 0, 110, '2023-04-17 03:09:02', NULL),
('25', 4203, 'test25', 4.66, 5.825, 5.592, 5.4522, 27, 17, 0, 125.82, '2023-04-17 03:09:02', NULL),
('26', 4203, 'test26', 4.65, 5.8125, 5.58, 5.4405, 23, 13, 0, 106.95, '2023-04-17 03:09:02', NULL),
('27', 4203, 'test27', 4.63, 5.7875, 5.556, 5.4171, 21, 11, 0, 97.23, '2023-04-17 03:09:02', NULL),
('28', 4199, 'test28', 5.7, 7.125, 6.84, 6.669, 27, 17, 0, 153.9, '2023-04-17 03:09:02', NULL),
('29', 4203, 'test29', 6.08, 7.6, 7.296, 7.1136, 27, 17, 0, 164.16, '2023-04-17 03:09:02', NULL),
('3', 4198, 'test3', 12.4, 15.5, 14.88, 14.508, 28, 19, 1, 347.2, '2023-04-25 21:46:19', NULL),
('30', 4199, 'test30', 5.9, 7.375, 7.08, 6.903, 22, 12, 0, 129.8, '2023-04-17 03:09:02', NULL),
('31', 4199, 'test31', 5.9, 7.375, 7.08, 6.903, 28, 18, 0, 165.2, '2023-04-17 03:09:02', NULL),
('32', 4199, 'test32', 5.9, 7.375, 7.08, 6.903, 29, 19, 0, 171.1, '2023-04-17 03:09:02', NULL),
('33', 4203, 'test33', 5.08, 6.35, 6.096, 5.9436, 21, 11, 0, 106.68, '2023-04-17 03:09:03', NULL),
('34', 4203, 'test34', 5.63, 7.0375, 6.756, 6.5871, 29, 19, 0, 163.27, '2023-04-17 03:09:03', NULL),
('35', 4197, 'test35', 5.9, 7.375, 7.08, 6.903, 29, 19, 0, 171.1, '2023-04-17 03:09:03', NULL),
('36', 4197, 'test36', 5.9, 7.375, 7.08, 6.903, 27, 17, 0, 159.3, '2023-04-17 03:09:03', NULL),
('37', 4193, 'test37', 5.33, 6.6625, 6.396, 6.2361, 21, 12, 1, 111.93, '2023-04-25 21:46:20', NULL),
('38', 4201, 'test38', 8.9, 11.125, 10.68, 10.413, 21, 11, 0, 186.9, '2023-04-17 03:09:03', NULL),
('39', 4199, 'test39', 5.7, 7.125, 6.84, 6.669, 21, 11, 0, 119.7, '2023-04-17 03:09:03', NULL),
('4', 4191, 'test4', 3.25, 4.0625, 3.9, 3.8025, 22, 16, 4, 71.5, '2023-04-25 21:59:08', NULL),
('40', 4200, 'test40', 18.29, 22.8625, 21.948, 21.3993, 20, 11, 1, 365.8, '2023-04-25 21:59:08', NULL),
('41', 4191, 'test41', 2.8, 3.5, 3.36, 3.276, 27, 18, 1, 75.6, '2023-04-25 21:46:20', NULL),
('42', 4197, 'test42', 1, 1.25, 1.2, 1.17, 19, 10, 1, 19, '2023-04-25 20:49:06', NULL),
('43', 4191, 'test43', 3.25, 4.0625, 3.9, 3.8025, 21, 11, 0, 68.25, '2023-04-17 03:09:03', NULL),
('44', 4200, 'test44', 3.1, 3.875, 3.72, 3.627, 30, 20, 0, 93, '2023-04-17 03:09:03', NULL),
('45', 4200, 'test45', 3.39, 4.2375, 4.068, 3.9663, 21, 11, 0, 71.19, '2023-04-17 03:09:03', NULL),
('46', 4202, 'test46', 1.3, 1.625, 1.56, 1.521, 20, 10, 0, 26, '2023-04-17 03:09:04', NULL),
('47', 4202, 'test47', 1.99, 2.4875, 2.388, 2.3283, 28, 18, 0, 55.72, '2023-04-17 03:09:04', NULL),
('48', 4207, 'test48', 1, 1.25, 1.2, 1.17, 29, 19, 0, 29, '2023-04-17 03:09:04', NULL),
('49', 4203, 'test49', 5.4, 6.75, 6.48, 6.318, 23, 13, 0, 124.2, '2023-04-17 03:09:04', NULL),
('5', 4203, 'test5', 5.15, 6.4375, 6.18, 6.0255, 23, 13, 0, 118.45, '2023-04-17 03:08:56', NULL),
('50', 4207, 'test50', 0.53, 0.6625, 0.636, 0.6201, 25, 15, 0, 13.25, '2023-04-17 03:09:04', NULL),
('51', 4195, 'test51', 0.9, 1.125, 1.08, 1.053, 23, 13, 0, 20.7, '2023-04-17 03:09:04', NULL),
('52', 4195, 'test52', 0.9, 1.125, 1.08, 1.053, 25, 15, 0, 22, '2023-04-17 03:09:04', NULL),
('53', 4195, 'test53', 0.67, 0.8375, 0.804, 0.7839, 30, 20, 0, 20, '2023-04-17 03:09:04', NULL),
('54', 4199, 'test54', 1.39, 1.7375, 1.668, 1.6263, 22, 12, 0, 30, '2023-04-17 03:09:04', NULL),
('55', 4199, 'test55', 1.37, 1.7375, 1.668, 1.6263, 29, 20, 1, 39.61, '2023-04-25 21:46:20', NULL),
('56', 4197, 'test56', 1.39, 1.7375, 1.668, 1.6263, 21, 11, 0, 29, '2023-04-17 03:09:04', NULL),
('57', 4197, 'test57', 1.36, 1.7375, 1.668, 1.6263, 24, 15, 1, 32.61, '2023-04-18 01:10:59', NULL),
('58', 4197, 'test58', 2.8, 3.5, 3.36, 3.276, 21, 11, 0, 58, '2023-04-17 03:09:04', NULL),
('59', 4197, 'test59', 2.6, 3.25, 3.12, 3.042, 22, 12, 0, 57, '2023-04-17 03:09:05', NULL),
('6', 4198, 'test6', 9.8, 12.25, 11.76, 11.466, 29, 19, 0, 284.2, '2023-04-17 03:08:56', NULL),
('60', 4197, 'test60', 2.6, 3.25, 3.12, 3.042, 24, 14, 0, 62, '2023-04-17 03:09:05', NULL),
('61', 4202, 'test61', 2.19, 2.7375, 2.628, 2.5623, 24, 14, 0, 53, '2023-04-17 03:09:05', NULL),
('62', 4199, 'test62', 2.19, 2.7375, 2.628, 2.5623, 28, 18, 0, 61, '2023-04-17 03:09:05', NULL),
('63', 4201, 'test63', 3.4, 4.25, 4.08, 3.978, 25, 15, 0, 85, '2023-04-17 03:09:05', NULL),
('64', 4207, 'test64', 0.5, 0.625, 0.6, 0.585, 28, 18, 0, 14, '2023-04-17 03:09:05', NULL),
('65', 4204, 'test65', 0.88, 1.1, 1.056, 1.0296, 24, 14, 0, 21, '2023-04-17 03:09:06', NULL),
('66', 4197, 'test66', 1.5, 1.875, 1.8, 1.755, 24, 14, 0, 36, '2023-04-17 03:09:06', NULL),
('67', 4207, 'test67', 0.37, 0.4625, 0.444, 0.4329, 29, 19, 0, 11, '2023-04-17 03:09:06', NULL),
('68', 4207, 'test68', 0.68, 0.85, 0.816, 0.7956, 21, 11, 0, 14, '2023-04-17 03:09:06', NULL),
('69', 4207, 'test69', 0.52, 0.65, 0.624, 0.6084, 24, 14, 0, 12, '2023-04-17 03:09:06', NULL),
('7', 4197, 'test7', 7.49, 9.3625, 8.988, 8.7633, 27, 17, 0, 202.23, '2023-04-17 03:08:56', NULL),
('70', 4207, 'test70', 0.52, 0.65, 0.624, 0.6084, 20, 10, 0, 10, '2023-04-17 03:09:06', NULL),
('71', 4207, 'test71', 0.52, 0.65, 0.624, 0.6084, 23, 13, 0, 11, '2023-04-17 03:09:06', NULL),
('72', 4207, 'test72', 0.47, 0.5875, 0.564, 0.5499, 27, 17, 0, 13, '2023-04-17 03:09:06', NULL),
('73', 4207, 'test73', 0.47, 0.5875, 0.564, 0.5499, 24, 14, 0, 11, '2023-04-17 03:09:07', NULL),
('74', 4207, 'test74', 0.47, 0.5875, 0.564, 0.5499, 29, 19, 0, 14, '2023-04-17 03:09:07', NULL),
('75', 4207, 'test75', 0.9, 1.125, 1.08, 1.053, 29, 19, 0, 26, '2023-04-17 03:09:07', NULL),
('76', 4204, 'test76', 0.62, 0.775, 0.744, 0.7254, 24, 14, 0, 15, '2023-04-17 03:09:07', NULL),
('77', 4207, 'test77', 0.56, 0.7, 0.672, 0.6552, 22, 12, 0, 12, '2023-04-17 03:09:07', NULL),
('78', 4204, 'test78', 0.5, 0.625, 0.6, 0.585, 25, 15, 0, 13, '2023-04-17 03:09:07', NULL),
('79', 4197, 'test79', 1.8, 2.25, 2.16, 2.106, 28, 18, 0, 50, '2023-04-17 03:09:07', NULL),
('8', 4197, 'test8', 8, 10, 9.6, 9.36, 26, 16, 0, 208, '2023-04-17 03:08:56', NULL),
('80', 4200, 'test80', 3.68, 4.6125, 4.428, 4.3173, 21, 12, 1, 77.31, '2023-04-25 21:46:19', NULL),
('81', 4201, 'test81', 2.8, 3.5, 3.36, 3.276, 27, 17, 0, 76, '2023-04-17 03:09:07', NULL),
('82', 4207, 'test82', 0.33, 0.4125, 0.396, 0.3861, 22, 12, 0, 7, '2023-04-17 03:09:07', NULL),
('83', 4207, 'test83', 0.43, 0.5375, 0.516, 0.5031, 20, 10, 0, 9, '2023-04-17 03:09:08', NULL),
('84', 4204, 'test84', 0.75, 0.9375, 0.9, 0.8775, 29, 19, 0, 22, '2023-04-17 03:09:08', NULL),
('85', 4207, 'test85', 0.6, 0.75, 0.72, 0.702, 28, 18, 0, 17, '2023-04-17 03:09:08', NULL),
('86', 4207, 'test86', 0.85, 1.0625, 1.02, 0.9945, 21, 11, 0, 18, '2023-04-17 03:09:08', NULL),
('87', 4204, 'test87', 0.92, 1.15, 1.104, 1.0764, 26, 16, 0, 24, '2023-04-17 03:09:08', NULL),
('88', 4204, 'test88', 1.06, 1.325, 1.272, 1.2402, 23, 13, 0, 24, '2023-04-17 03:09:08', NULL),
('89', 4199, 'test89', 1.5, 1.875, 1.8, 1.755, 26, 16, 0, 31, '2023-04-17 03:09:08', NULL),
('9', 4196, 'test9', 10, 11.4875, 11.028, 10.7523, 15, 16, 11, 150, '2023-04-18 01:17:06', NULL),
('90', 4199, 'test90', 1.5, 1.875, 1.8, 1.755, 21, 11, 0, 31.5, '2023-04-17 03:09:08', NULL),
('91', 4201, 'test91', 2.6, 3.25, 3.12, 3.042, 23, 13, 0, 59.8, '2023-04-17 03:09:08', NULL),
('92', 4201, 'test92', 3, 3.75, 3.6, 3.51, 21, 11, 0, 63, '2023-04-17 03:09:08', NULL),
('93', 4201, 'test93', 3.2, 4, 3.84, 3.744, 26, 16, 0, 83.2, '2023-04-17 03:09:08', NULL),
('94', 4199, 'test94', 2.89, 3.6125, 3.468, 3.3813, 25, 15, 0, 72.25, '2023-04-17 03:09:08', NULL),
('95', 4207, 'test95', 0.57, 0.7125, 0.684, 0.6669, 21, 11, 0, 12, '2023-04-17 03:09:09', NULL),
('96', 4207, 'test96', 0.53, 0.6625, 0.636, 0.6201, 22, 12, 0, 11.66, '2023-04-17 03:09:09', NULL),
('97', 4208, 'Testcable', 1, 4, 2, 3, 89, 110, 21, 89, '2023-04-25 21:46:20', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(11) NOT NULL,
  `ruc` varchar(45) DEFAULT NULL,
  `razon_social` varchar(100) DEFAULT NULL,
  `direccion` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`id`, `ruc`, `razon_social`, `direccion`) VALUES
(121, 'RT1825', 'Ricardo Torres', 'Enrique Segoviano #182'),
(122, 'JN7855', 'Juan Noyola', 'Martinez Ponce #785'),
(123, 'FN1207', 'Fernando Negrete', 'Roma #120'),
(124, 'GG4545', 'Griselda Guerrero', 'Rio Torrencial #454'),
(125, 'BB1211', 'Brenda Basilio', 'Zapopan #121'),
(126, 'AZ1912', 'Andrea Zapata', 'Corte Fino #191'),
(127, 'HC7350', 'Hernan Cortes', 'Delgadillo #735'),
(128, 'DF7130', 'David Flores', 'Arriba Abajo #713'),
(129, 'YT7419', 'Yessenia Toledo', 'Mercurio #419'),
(130, 'UV1999', 'Uriel Valdez', 'Aguas Profundas #199');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_cliente`
--

CREATE TABLE `tipo_cliente` (
  `id_tcliente` int(11) NOT NULL,
  `nombre` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `tipo_cliente`
--

INSERT INTO `tipo_cliente` (`id_tcliente`, `nombre`) VALUES
(1, 'FISICO'),
(2, 'MORAL');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_comprobante`
--

CREATE TABLE `tipo_comprobante` (
  `id` varchar(3) NOT NULL,
  `descripcion` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(100) DEFAULT NULL,
  `apellido_usuario` varchar(100) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `clave` text DEFAULT NULL,
  `id_perfil_usuario` int(11) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre_usuario`, `apellido_usuario`, `usuario`, `clave`, `id_perfil_usuario`, `estado`) VALUES
(1, 'Admin', 'Main', 'admin', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 1, 1),
(2, 'Víctor Hugo', 'Jiménez Torres', 'VHJT', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 2, 1),
(3, 'Admin Main ', 'Admin Main', 'admin@admin.com', '123456', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_cabecera`
--

CREATE TABLE `venta_cabecera` (
  `nro_boleta` varchar(8) CHARACTER SET utf8 NOT NULL,
  `descripcion` text CHARACTER SET utf8 DEFAULT NULL,
  `subtotal` float NOT NULL,
  `igv` float NOT NULL,
  `total_venta` float DEFAULT NULL,
  `fecha_venta` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `venta_cabecera`
--

INSERT INTO `venta_cabecera` (`nro_boleta`, `descripcion`, `subtotal`, `igv`, `total_venta`, `fecha_venta`) VALUES
('00000258', 'Venta realizada con Nro Boleta: 00000258', 0, 0, 40, '2023-04-18 01:08:18'),
('00000259', 'Venta realizada con Nro Boleta: 00000259', 0, 0, 114.9, '2023-04-18 01:10:22'),
('00000260', 'Venta realizada con Nro Boleta: 00000260', 0, 0, 1.74, '2023-04-18 01:10:59'),
('00000261', 'Venta realizada con Nro Boleta: 00000261', 0, 0, 19.61, '2023-04-18 01:17:06'),
('00000262', 'Venta realizada con Nro Boleta: 00000262', 0, 0, 4.06, '2023-04-18 01:18:46'),
('00000263', 'Venta realizada con Nro Boleta: 00000263', 0, 0, 1.25, '2023-04-25 20:49:05'),
('00000264', 'Venta realizada con Nro Boleta: 00000264', 0, 0, 40.75, '2023-04-25 21:46:18'),
('00000265', 'Venta realizada con Nro Boleta: 00000265', 0, 0, 54.92, '2023-04-25 21:59:06');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_detalle`
--

CREATE TABLE `venta_detalle` (
  `id` int(11) NOT NULL,
  `nro_boleta` varchar(8) CHARACTER SET utf8 NOT NULL,
  `codigo_producto` varchar(20) CHARACTER SET utf8 NOT NULL,
  `cantidad` float NOT NULL,
  `costo_unitario_venta` float DEFAULT NULL,
  `precio_unitario_venta` float DEFAULT NULL,
  `total_venta` float NOT NULL,
  `fecha_venta` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `venta_detalle`
--

INSERT INTO `venta_detalle` (`id`, `nro_boleta`, `codigo_producto`, `cantidad`, `costo_unitario_venta`, `precio_unitario_venta`, `total_venta`, `fecha_venta`) VALUES
(149, '00000258', '97', 10, 1, 4, 40, '2023-04-17'),
(150, '00000259', '9', 10, 10, 11.4875, 114.9, '2023-04-17'),
(151, '00000260', '57', 1, 1.39, 1.7375, 1.74, '2023-04-17'),
(152, '00000261', '4', 2, 3.25, 4.0625, 8.12, '2023-04-17'),
(153, '00000261', '9', 1, 10, 11.4875, 11.49, '2023-04-17'),
(154, '00000262', '4', 1, 3.25, 4.0625, 4.06, '2023-04-17'),
(155, '00000263', '42', 1, 1, 1.25, 1.25, '2023-04-25'),
(156, '00000264', '80', 1, 3.69, 4.6125, 4.61, '2023-04-25'),
(157, '00000264', '3', 1, 12.4, 15.5, 15.5, '2023-04-25'),
(158, '00000264', '41', 1, 2.8, 3.5, 3.5, '2023-04-25'),
(159, '00000264', '10', 1, 3.79, 4.7375, 4.74, '2023-04-25'),
(160, '00000264', '55', 1, 1.39, 1.7375, 1.74, '2023-04-25'),
(161, '00000264', '97', 1, 1, 4, 4, '2023-04-25'),
(162, '00000264', '37', 1, 5.33, 6.6625, 6.66, '2023-04-25'),
(163, '00000265', '1', 1, 5.9, 7.375, 7.38, '2023-04-25'),
(164, '00000265', '2', 1, 12.1, 15.125, 15.12, '2023-04-25'),
(165, '00000265', '4', 1, 3.25, 4.0625, 4.06, '2023-04-25'),
(166, '00000265', '40', 1, 18.29, 22.8625, 22.86, '2023-04-25'),
(167, '00000265', '16', 1, 4.4, 5.5, 5.5, '2023-04-25');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_caja_idx` (`id_caja`),
  ADD KEY `fk_id_usuario_idx` (`id_usuario`);

--
-- Indices de la tabla `cajas`
--
ALTER TABLE `cajas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_Cliente`),
  ADD KEY `tipo_Persona` (`tipo_Persona`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_proveedor_idx` (`id_proveedor`),
  ADD KEY `fk_id_comprobante_idx` (`id_tipo_comprobante`),
  ADD KEY `fk_id_moneda_idx` (`id_moneda_comprobante`);

--
-- Indices de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_cod_producto_idx` (`codigo_producto`),
  ADD KEY `fk_id_compra_idx` (`id_compra`);

--
-- Indices de la tabla `empresa`
--
ALTER TABLE `empresa`
  ADD PRIMARY KEY (`id_empresa`);

--
-- Indices de la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_producto_idx` (`codigo_producto`);

--
-- Indices de la tabla `modulos`
--
ALTER TABLE `modulos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `monedas`
--
ALTER TABLE `monedas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  ADD PRIMARY KEY (`id_perfil`);

--
-- Indices de la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  ADD PRIMARY KEY (`idperfil_modulo`),
  ADD KEY `id_perfil` (`id_perfil`),
  ADD KEY `id_modulo` (`id_modulo`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`codigo_producto`),
  ADD UNIQUE KEY `codigo_producto_UNIQUE` (`codigo_producto`),
  ADD KEY `fk_id_categoria_idx` (`id_categoria_producto`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_cliente`
--
ALTER TABLE `tipo_cliente`
  ADD PRIMARY KEY (`id_tcliente`);

--
-- Indices de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD KEY `id_perfil_usuario` (`id_perfil_usuario`);

--
-- Indices de la tabla `venta_cabecera`
--
ALTER TABLE `venta_cabecera`
  ADD PRIMARY KEY (`nro_boleta`);

--
-- Indices de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_nro_boleta_idx` (`nro_boleta`),
  ADD KEY `fk_cod_producto_idx` (`codigo_producto`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cajas`
--
ALTER TABLE `cajas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4209;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `empresa`
--
ALTER TABLE `empresa`
  MODIFY `id_empresa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `kardex`
--
ALTER TABLE `kardex`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8648;

--
-- AUTO_INCREMENT de la tabla `modulos`
--
ALTER TABLE `modulos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT de la tabla `monedas`
--
ALTER TABLE `monedas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  MODIFY `id_perfil` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  MODIFY `idperfil_modulo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=240;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=131;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=168;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  ADD CONSTRAINT `fk_id_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD CONSTRAINT `clientes_ibfk_1` FOREIGN KEY (`tipo_Persona`) REFERENCES `tipo_cliente` (`id_tcliente`);

--
-- Filtros para la tabla `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `fk_id_comprobante` FOREIGN KEY (`id_tipo_comprobante`) REFERENCES `tipo_comprobante` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_moneda` FOREIGN KEY (`id_moneda_comprobante`) REFERENCES `monedas` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_proveedor` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD CONSTRAINT `fk_cod_producto` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_compra` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD CONSTRAINT `fk_cod_producto_kardex` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  ADD CONSTRAINT `id_modulo` FOREIGN KEY (`id_modulo`) REFERENCES `modulos` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `id_perfil` FOREIGN KEY (`id_perfil`) REFERENCES `perfiles` (`id_perfil`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_id_categoria` FOREIGN KEY (`id_categoria_producto`) REFERENCES `categorias` (`id_categoria`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_perfil_usuario`) REFERENCES `perfiles` (`id_perfil`);

--
-- Filtros para la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  ADD CONSTRAINT `fk_cod_producto_detalle` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_nro_boleta` FOREIGN KEY (`nro_boleta`) REFERENCES `venta_cabecera` (`nro_boleta`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
