<div class="content-header">
    <div class="container-fluid">
        <div class="row">
            <div class="col-md-4">
                <h4 class="m-0">Proveedores</h4>
            </div>
            <div class="col-md-4">
                <ol class="breadcrumb float-md-right">
                    <li class="breadcrumb-item"><a href="index.php">Inicio</a></li>
                    <li class="breadcrumb-item">Proveedores</li>
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
                    <h3 class="card-title"><i class="fas fa-truck-moving"></i>     Listado de Proovedores</h3>
                </div>
                <div class="card-body">
                    <table id="lstProveedores" class="display nowrap table-striped w-100 shadow rounded">
                        <thead class="bg-info text-left">
                            <th>ID</th> 
                            <th>RFC</th> 
                            <th>Razon Social</th> 
                            <th>Direccion</th> 
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