SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[api_Custom_MyForms]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[api_Custom_MyForms] AS' 
END
GO




-- =============================================
-- api_Custom_MyForms
-- =============================================
-- Description:		This stored procedure returns form responses for the user
-- Last Modified:	04/16/2024
-- Mac Willingham
-- Updates:
-- 4/16/24 Added Form Answers
-- =============================================

ALTER PROCEDURE [dbo].[api_custom_MyForms] 
	@DomainID int,
	@Username nvarchar(75)
	
AS
BEGIN

	DECLARE @contactID INT = (SELECT U.Contact_ID FROM dp_Users U WHERE U.User_Name=@Username)

-- Get Form Response IDs for User

	SELECT FR.Form_Response_ID
	INTO #FormResponses
	FROM Form_Responses FR
	INNER JOIN Contacts C ON C.Contact_ID = FR.Contact_ID
	INNER JOIN Forms F ON FR.Form_ID = F.Form_ID
	WHERE FR.Contact_ID = @contactID

-- DataSet 1: Get Form Responses
	SELECT 
		FR.Form_Response_ID
		,FR.Response_Date
		,F.Form_Title
	FROM Form_Responses FR
	INNER JOIN Contacts C ON C.Contact_ID = FR.Contact_ID
	INNER JOIN Forms F ON FR.Form_ID = F.Form_ID
	WHERE FR.Contact_ID = @contactID

-- DataSet 2: Get Form Response Answers

	SELECT
		FRA.Form_Response_ID
		,ISNULL(FF.Alternate_Label,FF.Field_Label) AS QuestionName
		,FRA.Response
	FROM Form_Response_Answers FRA
	INNER JOIN Form_Fields FF ON FF.Form_Field_ID = FRA.Form_Field_ID
	WHERE FRA.Form_Response_ID IN (SELECT Form_Response_ID FROM #FormResponses) 
	
	-- Clean up Temp Tables
	DROP TABLE #FormResponses

END

-- ========================================================================================
-- SP MetaData Install
-- ========================================================================================
DECLARE @spName nvarchar(128) = 'api_Custom_MyForms'
DECLARE @spDescription nvarchar(500) = 'Custom Widget SP for Form Responses'

IF NOT EXISTS (SELECT API_Procedure_ID FROM dp_API_Procedures WHERE Procedure_Name = @spName)
BEGIN
	INSERT INTO dp_API_Procedures
	(Procedure_Name, Description)
	VALUES
	(@spName, @spDescription)	
END


DECLARE @AdminRoleID INT = (SELECT Role_ID FROM dp_Roles WHERE Role_Name='Administrators')
IF NOT EXISTS (SELECT * FROM dp_Role_API_Procedures RP INNER JOIN dp_API_Procedures AP ON AP.API_Procedure_ID = RP.API_Procedure_ID WHERE AP.Procedure_Name = @spName AND RP.Role_ID=@AdminRoleID)
BEGIN
	INSERT INTO dp_Role_API_Procedures
	(Domain_ID,  API_Procedure_ID, Role_ID)
	VALUES
	(1, (SELECT API_Procedure_ID FROM dp_API_Procedures WHERE Procedure_Name = @spName), @AdminRoleID)
END
GO
-- ========================================================================================