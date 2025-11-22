(Get-Content config.w32) | ForEach-Object { $_ -replace '/sdl', '' } | Set-Content config.w32
(Get-Content php_pdo_sqlsrv_int.h) | ForEach-Object { $_.replace('zval_ptr_dtor( &dbh->query_stmt_zval );', 'OBJ_RELEASE(dbh->query_stmt_obj);dbh->query_stmt_obj = NULL;') } | Set-Content php_pdo_sqlsrv_int.h
(Get-Content pdo_dbh.cpp) | ForEach-Object { $_ -replace 'pdo_error_mode prev_err_mode', 'uint8_t prev_err_mode' } | Set-Content pdo_dbh.cpp
