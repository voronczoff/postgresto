--liquibase formatted sql
--changeset postgresto:fn-reload_schema runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- Ask PostgREST to reload its schema cache so newly created tables/views/RPCs
-- appear in OpenAPI without restarting the API process.
--
-- SELECT postgresto.reload_schema();
CREATE OR REPLACE FUNCTION postgresto.reload_schema()
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
BEGIN
  PERFORM pg_notify('pgrst', 'reload schema');
  RETURN jsonb_build_object(
    'ok', true,
    'message', 'PostgREST schema reload notified'
  );
END;
$function$;
