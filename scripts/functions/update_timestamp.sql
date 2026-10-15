--liquibase formatted sql
--changeset postgresto:fn-update_timestamp runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- BEFORE UPDATE helper: set updated_at to UTC now().

CREATE OR REPLACE FUNCTION postgresto.update_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = timezone('UTC', now());
    RETURN NEW;
END;
$function$;
