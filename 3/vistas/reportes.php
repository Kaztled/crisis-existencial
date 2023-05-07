<!-- Content Header (Page header) -->
<div class="content-header">
    <div class="container-fluid">
        <div class="row mb-2">
            <div class="col-sm-6">
                <h2 class="m-0">Reportes </h2>
            </div><!-- /.col -->
            <div class="col-sm-6">
                <ol class="breadcrumb float-sm-right">
                    <li class="breadcrumb-item"><a href="#">Inicio</a></li>
                    <li class="breadcrumb-item active">Reportes</li>
                </ol>
            </div><!-- /.col -->
        </div><!-- /.row -->
    </div><!-- /.container-fluid -->
</div>
<!-- /.content-header -->

<!-- Main content -->
<div class="content">

    <div class="container-fluid">

        <!-- row para criterios de busqueda -->
        <div class="row">

            <div class="col-lg-12">

                <div class="card card-gray shadow">
                    <div class="card-header">
                        <h3 class="card-title">CRITERIOS DE BÚSQUEDA</h3>
                        <div class="card-tools">
                            <button type="button" class="btn btn-tool" data-card-widget="collapse">
                                <i class="fas fa-minus"></i>
                            </button>
                            <button type="button" class="btn btn-tool text-warning" id="btnLimpiarBusqueda">
                                <i class="fas fa-times"></i>
                            </button>
                        </div> <!-- ./ end card-tools -->
                    </div> <!-- ./ end card-header -->
                    <div class="card-body">

                        <div class="row">

                            <div class="d-none d-md-flex col-md-12 ">

                                <div style="width: 20%;" class="form-floating mx-1">
                                    <input type="text" id="iptProducto" class="form-control" data-index="4">
                                    <label for="iptProducto">Producto</label>
                                </div>

                                <div style="width: 20%;" class="form-floating mx-1">
                                    <input type="date" id="iptVentaDesde" class="form-control">
                                    <label for="iptPrecioVentaDesde">Venta Desde</label>
                                </div>

                                <div style="width: 20%;" class="form-floating mx-1">
                                    <input type="date" id="iptVentaHasta" class="form-control">
                                    <label for="iptPrecioVentaHasta">Venta Hasta</label>
                                </div>
                                <div style="width: 20%;" class=" mx-1">
                                    <input type="submit" id="iptBusquedaButton" value="BUSCAR" class="form-control btn btn-primary">
                                </div>
                            </div>

                            <div class="d-block d-sm-none">

                                <div style="width: 100%;" class="form-floating mx-1 my-1">
                                    <input type="text" id="iptProducto" class="form-control" data-index="4">
                                    <label for="iptProducto">Producto</label>
                                </div>

                                <div style="width: 100%;" class="form-floating mx-1 my-1">
                                    <input type="text" id="iptPrecioVentaDesde" class="form-control">
                                    <label for="iptPrecioVentaDesde">P. Venta Desde</label>
                                </div>

                                <div style="width: 100%;" class="form-floating mx-1 my-1">
                                    <input type="text" id="iptPrecioVentaHasta" class="form-control">
                                    <label for="iptPrecioVentaHasta">P. Venta Hasta</label>
                                </div>
                            </div>

                        </div>
                    </div> <!-- ./ end card-body -->
                </div>

            </div>

        </div>

        <!-- row para listado de productos/inventario -->
        <div class="row">
            <div class="col-lg-12">
                <table id="tbl_productos" class="table table-striped w-100 shadow border border-secondary">
                    <thead class="bg-gray">
                        <tr style="font-size: 15px;">
                            <th></th><!-- 0 -->
                            <th>Boleta</th> <!-- 1 -->
                            <th>Codigo Producto</th> <!-- 2 -->
                            <th>Nombre Categoria</th> <!-- 3 -->
                            <th>Descripcion</th> <!-- 4 -->
                            <th>Cantidad</th> <!-- 5 -->
                            <th>Total</th> <!-- 6 -->
                            <th>Ventas Totales</th> 
                            <th>Stock</th>
                            <th>Fecha</th>
                            
                        </tr>
                    </thead>
                    <tbody class="text-small">
                    </tbody>
                </table>
            </div>
        </div>

    </div><!-- /.container-fluid -->

</div>



<script>
    var accion;
    var table;
    var operacion_stock = 0; // permitar definir si vamos a sumar o restar al stock (1: sumar, 2:restar)

    /*===================================================================*/
    //INICIALIZAMOS EL MENSAJE DE TIPO TOAST (EMERGENTE EN LA PARTE SUPERIOR)
    /*===================================================================*/
    var Toast = Swal.mixin({
        toast: true,
        position: 'top',
        showConfirmButton: false,
        timer: 3000
    });

    $(document).ready(function() {


        /*===================================================================*/
        // CARGA DEL LISTADO CON EL PLUGIN DATATABLE JS
        /*===================================================================*/
        table = $("#tbl_productos").DataTable({
            dom: 'Bfrtip',
            buttons: [
                    
                    
                    
                'excel', 'print', 'pageLength'
            ],
            pageLength: [5, 10, 15, 30, 50, 100],
            pageLength: 10,
            ajax: {
                url: "ajax/ventas.ajax.php",
                dataSrc: '',
                type: "POST",
                data: {
                    'accion': 2, //1: LISTAR PRODUCTOS
                    "fechaDesde": "2028-04-17",
                    "fechaHasta": "2028-04-30"
                },
            },
            responsive: {
                details: {
                    type: 'column'
                }
            },
            columnDefs: [{
                    targets: 0,
                    orderable: true,
                    className: 'control'
                },
                {
                    targets: 1,
                    visible: true
                }

            ],
            language: {
                url: "//cdn.datatables.net/plug-ins/1.10.20/i18n/Spanish.json"
            }
        });

        /*===================================================================*/
        // EVENTOS PARA CRITERIOS DE BUSQUEDA (CODIGO, CATEGORIA Y PRODUCTO)
        /*===================================================================*/


        $("#iptProducto").keyup(function() {
            table.column($(this).data('index')).search(this.value).draw();
            console.log($(this).data('index'))
        })

        /*===================================================================*/
        // EVENTOS PARA CRITERIOS DE BUSQUEDA POR RANGO (PREVIO VENTA)
        /*===================================================================*/
        $("#iptPrecioVentaDesde, #iptPrecioVentaHasta").keyup(function() {
            table.draw();
        })

        $.fn.dataTable.ext.search.push(

            function(settings, data, dataIndex) {
                console.log(data)

                var precioDesde = parseFloat($("#iptPrecioVentaDesde").val());
                var precioHasta = parseFloat($("#iptPrecioVentaHasta").val());

                var col_venta = parseFloat(data[6]);

                if ((isNaN(precioDesde) && isNaN(precioHasta)) ||
                    (isNaN(precioDesde) && col_venta <= precioHasta) ||
                    (precioDesde <= col_venta && isNaN(precioHasta)) ||
                    (precioDesde <= col_venta && col_venta <= precioHasta)) {
                    return true;
                }

                return false;
            }
        )

        /*===================================================================*/
        // EVENTO PARA LIMPIAR INPUTS DE CRITERIOS DE BUSQUEDA
        /*===================================================================*/
        $("#btnLimpiarBusqueda").on('click', function() {


            $("#iptProducto").val('')
            $("#iptPrecioVentaDesde").val('')
            $("#iptPrecioVentaHasta").val('')

            table.search('').columns().search('').draw();
        })


        /* ======================================================================================
        EVENTO AL DAR CLICK EN EL BOTON AUMENTAR STOCK
        =========================================================================================*/
        $('#tbl_productos tbody').on('click', '.btnAumentarStock', function() {

            operacion_stock = 1; //sumar stock
            accion = 3;

            $("#mdlGestionarStock").modal('show'); //MOSTRAR VENTANA MODAL

            $("#titulo_modal_stock").html('Aumentar Stock'); // CAMBIAR EL TITULO DE LA VENTANA MODAL
            $("#titulo_modal_label").html('Agregar al Stock'); // CAMBIAR EL TEXTO DEL LABEL DEL INPUT PARA INGRESO DE STOCK
            $("#iptStockSumar").attr("placeholder", "Ingrese cantidad a agregar al Stock"); //CAMBIAR EL PLACEHOLDER 

            var data = table.row($(this).parents('tr')).data(); //OBTENER EL ARRAY CON LOS DATOS DE CADA COLUMNA DEL DATATABLE

            $("#stock_codigoProducto").html(data[1]) //CODIGO DEL PRODUCTO DEL DATATABLE
            $("#stock_Producto").html(data[4]) //NOMBRE DEL PRODUCTO DEL DATATABLE
            $("#stock_Stock").html(data[9]) //STOCK ACTUAL DEL PRODUCTO DEL DATATABLE

            $("#stock_NuevoStock").html(parseFloat($("#stock_Stock").html()));

        })

        /* ======================================================================================
        EVENTO AL DAR CLICK EN EL BOTON DISMINUIR STOCK
        =========================================================================================*/
        $('#tbl_productos tbody').on('click', '.btnDisminuirStock', function() {

            operacion_stock = 2; //restar stock
            accion = 3;
            $("#mdlGestionarStock").modal('show'); //MOSTRAR VENTANA MODAL

            $("#titulo_modal_stock").html('Disminuir Stock'); // CAMBIAR EL TITULO DE LA VENTANA MODAL
            $("#titulo_modal_label").html('Disminuir al Stock'); // CAMBIAR EL TEXTO DEL LABEL DEL INPUT PARA INGRESO DE STOCK
            $("#iptStockSumar").attr("placeholder", "Ingrese cantidad a disminuir al Stock"); //CAMBIAR EL PLACEHOLDER 


            var data = table.row($(this).parents('tr')).data(); //OBTENER EL ARRAY CON LOS DATOS DE CADA COLUMNA DEL DATATABLE

            $("#stock_codigoProducto").html(data[1]) //CODIGO DEL PRODUCTO DEL DATATABLE
            $("#stock_Producto").html(data[4]) //NOMBRE DEL PRODUCTO DEL DATATABLE
            $("#stock_Stock").html(data[9]) //STOCK ACTUAL DEL PRODUCTO DEL DATATABLE

            $("#stock_NuevoStock").html(parseFloat($("#stock_Stock").html()));

        })

        /* ======================================================================================
        EVENTO QUE LIMPIA EL INPUT DE INGRESO DE STOCK AL CERRAR LA VENTANA MODAL
        =========================================================================================*/
        $("#btnCancelarRegistroStock, #btnCerrarModalStock").on('click', function() {
            $("#iptStockSumar").val("")
        })

        /* ======================================================================================
        EVENTO AL DIGITAR LA CANTIDAD A AUMENTAR O DISMINUIR DEL STOCK
        =========================================================================================*/
        $("#iptStockSumar").keyup(function() {

            // console.log($("#iptStockSumar").val());

            if (operacion_stock == 1) {

                if ($("#iptStockSumar").val() != "" && $("#iptStockSumar").val() > 0) {

                    var stockActual = parseFloat($("#stock_Stock").html());
                    var cantidadAgregar = parseFloat($("#iptStockSumar").val());

                    $("#stock_NuevoStock").html(stockActual + cantidadAgregar);

                } else {

                    // Toast.fire({
                    //     icon: 'warning',
                    //     title: 'Ingrese un valor mayor a 0'
                    // });

                    mensajeToast('error', 'Ingrese un valor mayor a 0');

                    $("#iptStockSumar").val("")
                    $("#stock_NuevoStock").html(parseFloat($("#stock_Stock").html()));

                }

            } else {

                if ($("#iptStockSumar").val() != "" && $("#iptStockSumar").val() > 0) {

                    var stockActual = parseFloat($("#stock_Stock").html());
                    var cantidadAgregar = parseFloat($("#iptStockSumar").val());

                    $("#stock_NuevoStock").html(stockActual - cantidadAgregar);

                    if (parseInt($("#stock_NuevoStock").html()) < 0) {

                        // Toast.fire({
                        //     icon: 'warning',
                        //     title: 'La cantidad a disminuir no puede ser mayor al stock actual (Nuevo stock < 0)'
                        // });

                        mensajeToast('error', 'La cantidad a disminuir no puede ser mayor al stock actual (Nuevo stock < 0)');

                        $("#iptStockSumar").val("");
                        $("#iptStockSumar").focus();
                        $("#stock_NuevoStock").html(parseFloat($("#stock_Stock").html()));
                    }
                } else {

                    // Toast.fire({
                    //     icon: 'warning',
                    //     title: 'Ingrese un valor mayor a 0'
                    // });

                    mensajeToast('error', 'Ingrese un valor mayor a 0');

                    $("#iptStockSumar").val("")
                    $("#stock_NuevoStock").html(parseFloat($("#stock_Stock").html()));
                }
            }

        })


        /* ======================================================================================
        EVENTO AL DAR CLICK EN EL BOTON ELIMINAR PRODUCTO
        =========================================================================================*/
        $('#tbl_productos tbody').on('click', '.btnEliminarProducto', function() {

            accion = 5; //seteamos la accion para editar

            var data = table.row($(this).parents('tr')).data();

            var codigo_producto = data["codigo_producto"];

            Swal.fire({
                title: 'Está seguro de eliminar el producto?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                confirmButtonText: 'Si, deseo eliminarlo!',
                cancelButtonText: 'Cancelar',
            }).then((result) => {

                if (result.isConfirmed) {

                    var datos = new FormData();

                    datos.append("accion", accion);
                    datos.append("codigo_producto", codigo_producto); //codigo_producto               

                    $.ajax({
                        url: "ajax/ventas.ajax.php",
                        method: "POST",
                        data: datos,
                        cache: false,
                        contentType: false,
                        processData: false,
                        dataType: 'json',
                        success: function(respuesta) {

                            if (respuesta == "ok") {

                                Toast.fire({
                                    icon: 'success',
                                    title: 'El producto se eliminó correctamente'
                                });

                                table.ajax.reload();

                            } else {
                                Toast.fire({
                                    icon: 'error',
                                    title: 'El producto no se pudo eliminar'
                                });
                            }

                        }
                    });

                }
            })
        })


    });



    $('#iptBusquedaButton').on('click', function(){
            console.log('puta')
            console.log($('#iptVentaDesde').val(), $('#iptVentaHasta').val())
            table = $("#tbl_productos").DataTable({
                destroy: true,
                dom: 'Bfrtip',
                buttons: [                     
                    'excel', 'print', 'pageLength'
                ],
                pageLength: [5, 10, 15, 30, 50, 100],
                pageLength: 10,
                ajax: {
                    url: "ajax/ventas.ajax.php",
                    dataSrc: '',
                    type: "POST",
                    data: {
                        'accion': 3, //1: LISTAR PRODUCTOS
                        "fechaDesde": $('#iptVentaDesde').val(),
                        "fechaHasta": $('#iptVentaHasta').val(),
                        "codigo": $("#iptProducto").val()
                    },
                },
                responsive: {
                    details: {
                        type: 'column'
                    }
                },
                columnDefs: [{
                        targets: 0,
                        orderable: true,
                        className: 'control'
                    },
                    {
                        targets: 1,
                        visible: true
                    }

                ],
                language: {
                    url: "//cdn.datatables.net/plug-ins/1.10.20/i18n/Spanish.json"
                }
            });
        })

</script>
