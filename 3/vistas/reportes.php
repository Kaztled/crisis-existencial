<?php

// Perform any necessary PHP tasks, such as connecting to a database

// Generate dynamic content
$ventas_desde = $_GET['ventas_desde'] ?? '';
$ventas_hasta = $_GET['ventas_hasta'] ?? '';
?>

<div class="content-header">
    <div class="container-fluid">
        <div class="row mb-2">
            <div class="col-md-6">
                <h2 class="m-0">Administrar Ventas</h2>
            </div>
            <div class="col-md-6">
                <ol class="breadcrumb float-md-right">
                    <li class="breadcrumb-item"><a href="index.php">Inicio</a></li>
                    <li class="breadcrumb-item">Ventas</li>
                    <li class="breadcrumb-item active">Administrar Ventas</li>
                </ol>
            </div>
        </div>
    </div>
</div>


<div class="content pb-2">
    <div class="container-fluid">
        <div class="row">
            <div class="col-md-12">
                <div class="card card-gray shadow">
                    <div class="card-header">
                        <h3 class="card-title">Criterios de Busqueda</h3>
                        <div class="card-tools"><button class="btn btn-tool" type="button" data-card-widget="collapse"><i class="fas fa-minus"></i></button></div>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-2">
                                <div class="form-group">
                                    <label for="">Ventas desde:</label>
                                    <div class="input-group">
                                        <div class="input-group-prepend"><span class="input-group-text"><i class="far fa-calendar-alt"></i></span></div>
                                        <input type="text" class="form-control" data-inputmask-alias="datetime" data-inputmask-inputformat="dd/mm/yyyy" id="ventas_desde" value="<?php echo $ventas_desde; ?>">
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-2">
                                <div class="form-group">
                                    <label for="">Ventas hasta:</label>
                                    <div class="input-group">
                                        <div class="input-group-prepend"><span class="input-group-text"><i class="far fa-calendar-alt"></i></span></div>
                                        <input type="text" class="form-control" data-inputmask-alias="datetime" data-inputmask-inputformat="dd/mm/yyyy" id="ventas_hasta" value="<?php echo $ventas_hasta; ?>">
                                    </div>
                                </div>
                            </div>

                            
                            <div class="col-md-8 d-flex-row-reverse">
                            <div id="search-form">
    <form action="">
        <!-- form inputs here -->
        <button type="submit" class="btn btn-primary">Buscar</button>
    </form>
</div>
<button class="btn btn-default" onclick="limpiarFiltros()">Limpiar Filtros</button>
</div>
</div>
</div>
</div>
</div>
</div>
<div class="row">
        <div class="col-md-12">
            <div class="card card-gray shadow">
                <div class="card-header">
                    <h3 class="card-title">Ventas Registradas</h3>
                </div>
                <div class="card-body">
                    <table class="table table-striped table-hover" id="tabla_ventas">
                        <thead>
                            <tr>
                                <th>ID Venta</th>
                                <th>Fecha de Venta</th>
                                <th>Cliente</th>
                                <th>Producto</th>
                                <th>Cantidad</th>
                                <th>Total</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            // Fetch and display data from the database based on search criteria
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

</div>
</div>
<script>
    // Define functions for searching and clearing filters
    function buscarVentas() {
        var ventas_desde = $('#ventas_desde').val();
        var ventas_hasta = $('#ventas_hasta').val();
        // Add code to send AJAX request and update table with search results
    }

    function limpiarFiltros() {
        $('#ventas_desde').val('');
        $('#ventas_hasta').val('');
        // Add code to clear search results and reset table to default state
    }
</script>