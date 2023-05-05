
<div class="content-header">
    <div class="container-fluid">
        <div class="row">
            <div class="col-md-12">
                <h4 class="m-0">Clientes</h4>
            </div>
            <div class="col-md-4">
                <ol class="breadcrumb float-md-right">
                    <li class="breadcrumb-item"><a href="index.php">Inicio</a></li>
                    <li class="breadcrumb-item">Clientes</li>
                    <li class="breadcrumb-item active">Listado</li>

                </ol>
            </div>
        </div>
    </div>
</div>

<div class="content pb-2"> 
    <div class="row p-0 m-0">
        <div class="col-md-8">
            <div class="card card-info card-outline shadow">
                <div class="card-header">
                    <h3 class="card-title"><i class="fa fa-address-book"></i>     Listado de Clientes</h3>
                </div>
                <div class="card-body">
                <table id="lstProveedores" class="display nowrap table-striped w-100 shadow rounded">
    <thead class="bg-info text-left">
        <th data-priority="1">ID</th> 
        <th data-priority="2">Nombre</th> 
        <th data-priority="4">Calle</th> 
        <th data-priority="4">Colonia</th> 
        <th data-priority="4">N Int</th>
        <th data-priority="4">N Ext</th>
        <th data-priority="3">CP</th>
        <th data-priority="3">Ciudad</th>
        <th data-priority="3">Estado</th> 
        <th data-priority="4">Regimen</th>
        <th data-priority="2">RFC</th>      
    </thead>
    <tbody class="small text left"></tbody>
</table>
              
</div>
</div>
</div>
</div>

<script>
    $(document).ready(function() {
        var tableProveedores = $('#lstProveedores').DataTable({
        dom:'Bfrtip',
        buttons: [
            'excel','print','pageLength',
        ],
        ajax:{
            url:"ajax/proveedores.ajax.php",
            dataSrc: ""
        },
        "order":[[0,'desc']],
        lengthmenu:[0,5,10,15,20,50],
        "pagelength":15,
        "language":{
            "url":"//cdn.datatables.net/plug-ins/1.10.20/i18n/Spanish.json"
        }
    });
    $('#lstProveedores').addClass('responsive');
    })

</script>