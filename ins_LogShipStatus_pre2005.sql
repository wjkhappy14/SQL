USE [Status]
GO
/****** Object:  StoredProcedure [dbo].[ins_LogShipStatus]    Script Date: 06/25/2009 11:14:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Required permissions:
The calling sproc(dbm_RestoreBAK) requires write access to Status.  Use the ProdStatuswrite user/linkedServer setup.
dbm_RestoreBAK calls ins_LogShipStatus which needs READ access to the CLIENT database server, specifically msdb.
Use LinkServerRead user/LinkedServer for this.  Each client server Linked Server should use LinkServerRead already.
ProdStatusWrite also needs execute access on ins_LogShipStatus.
ProdStatusWrite also needs delete/update access to LogShipStatus.

Notes:
This sproc will no longer work on pre-2005 versions of MSSQL.
*/

ALTER PROCEDURE [dbo].[ins_LogShipStatus]
@Server varchar(50),
@DB	 varchar(40)

AS

BEGIN
DECLARE @Runstring varchar(8000)


SELECT @Runstring =
' insert into logshipstatus (database_name,sequence_id,server_name,end_time,message)' + 
' select database_name,backup_set_id,server_name,backup_finish_date,name' + 
' from ' + @server + '.msdb.dbo.backupset ' + 
' where  type = ''D''' + 
' and database_name = ''' + @DB + '''' +
' and server_name = ''' + @server + '''' + 
' and backup_finish_date >= GetDate() - 1 '


Begin

-- delete records that are 7 days older than the most recent BAK backup
delete from logshipstatus where database_name = @DB and server_name = @Server and sequence_id < 
	(
	select max(sequence_id) from logshipstatus 
	where database_name = @DB 
	and server_name = @Server
	--and activity = 'Backup database'
	and LastUpdate < GetDate() - 6 
	)


IF EXISTS
	(
	select * from logshipstatus where database_name = @DB and server_name = @Server
	)
	SET @Runstring = @Runstring + ' and backup_set_id > (select max(sequence_id) from logshipstatus where database_name = ''' + @DB + ''' and server_name = ''' + @Server + ''')'
End

--Select (@Runstring)
EXEC(@Runstring)

END


