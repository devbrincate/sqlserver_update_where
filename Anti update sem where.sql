
use master
if db_id('DEV.BRINCANTE') is null
    create database [DEV.BRINCANTE]
go

go
use [DEV.BRINCANTE]
go
 
 IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'usuarios')) DROP TABLE usuarios
CREATE TABLE [usuarios](
	[id_usuario] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[nome] [varchar](100) NULL,
	[email] [varchar](100) NULL,
	[data_nascimento] [datetime] NULL
)
insert into usuarios values ('Rodolfo', 'rodolfo@gmail.com', '1985-01-01') 
insert into usuarios values ('Firme', 'Firme@gmail.com', '1985-01-02')
insert into usuarios values ('Miguel', 'miguel@microsoft.com', '1985-01-03')
insert into usuarios values ('Andressa', 'andressa@outlook.com.br', '1985-01-04')
insert into usuarios values ('Thaiane', 'thaiane@hotmail.com.br', '1985-01-05')
insert into usuarios values ('Matheus', 'matheus@gmail.com', '1985-01-06')
insert into usuarios values ('Paloma', 'paloma@gmail.com', '1985-01-07')
insert into usuarios values ('Vanessa', 'vanessa@gmail.com', '1985-01-07')

go

select * from usuarios
 
 
 
--------------------------------------------------------
-- O erro
--------------------------------------------------------
update usuarios set [data_nascimento] = '1985-01-08'
 
 --------------------------------------------------------
-- SOLUÇÃO 1: TRANSACTION - ROLLBACK
--------------------------------------------------------

begin transaction

select * from usuarios
update usuarios set [data_nascimento] = '1985-01-08' where id_usuario = 8
select * from usuarios
--insert into usuarios values ('Karine', 'karina@gmail.com', '1985-01-09')

--rollback
commit

select * from usuarios

--------------------------------------------------------
-- SOLUÇÃO 2: Trigger - Verifica se a quantidade de linhas alteradas será o total de linhas
--------------------------------------------------------
-- Trigger para impedir
if object_id('tr_usuarios_impede_sem_where') is not null drop trigger tr_usuarios_impede_sem_where 
go
create trigger tr_usuarios_impede_sem_where on usuarios for update, delete
as begin
    declare @count int = @@rowcount
    if @count = (select sum(row_count) from sys.dm_db_partition_stats where object_id = object_id('usuarios') and index_id in (0,1))
        begin
            raiserror('ATENÇÃO: Não é permitido atualizar todos os registros de uma só vez. A transação foi cancelada.', 16, 1)
            rollback transaction
        end
end
go
 
 -- Exemplo com erro
update usuarios set [data_nascimento] = '1980-02-01'

-- Exemplo que funciona
update usuarios set [data_nascimento] = '1985-01-12' where id_usuario = 8

update usuarios set [data_nascimento] = '1980-02-01' where id_usuario > 6

select * from usuarios
go
 
-- Permitir update sem where temporário para ADMINS
alter table usuarios disable trigger tr_usuarios_impede_sem_where
update usuarios set [data_nascimento] = '1980-02-01'
alter table usuarios enable trigger tr_usuarios_impede_sem_where
go
 
 

 --------------------------------------------------------
-- SOLUÇÃO 3: Usando variável de contexto para permitir execução
--------------------------------------------------------
if object_id('tr_usuarios_impede_sem_where') is not null drop trigger tr_usuarios_impede_sem_where 
go
create trigger tr_usuarios_impede_sem_where on usuarios WITH ENCRYPTION for update, delete
as begin
    declare @count int = @@rowcount
    if context_info() = 0x5564747
        begin
            set context_info 0x -- reinicia o context_info para permitir apenas 1 execução sem where
            print 'Contexto admin, Liberado.'
        end
    else
        if @count = (select sum(row_count) from sys.dm_db_partition_stats where object_id = object_id('usuarios') and index_id in (0,1))
            begin
                raiserror('ATENÇÃO: Não é permitido atualizar todos os registros de uma só vez. A transação foi cancelada.', 16, 1)
                rollback transaction
            end
end
 
 
-- Usando variável de controle - context_info


select context_info from sys.dm_exec_sessions where session_id = @@spid;
update usuarios set data_nascimento = '1980-02-01' where id_usuario = 6
update usuarios set data_nascimento = '1980-02-01' where id_usuario between 1 and 3
update usuarios set data_nascimento = '1980-02-01'

set context_info 0x5564747;
update usuarios set data_nascimento = '1980-02-01'
set context_info 0x5564747;
update usuarios set data_nascimento = '1980-02-01' where id_usuario = 6
select * from usuarios
go