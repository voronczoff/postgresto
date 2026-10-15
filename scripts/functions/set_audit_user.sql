--liquibase formatted sql
--changeset postgresto:fn-set_audit_user runOnChange:true splitStatements:false logicalFilePath:functions/cumulative_changelog.xml
-- BEFORE INSERT OR UPDATE: set created_by / updated_by from JWT
-- preferred_username (Keycloak login). Client-supplied values are ignored when
-- the claim is present. No JWT (Liquibase / lab anon) → leave values alone
-- except created_by is always preserved on UPDATE.

CREATE OR REPLACE FUNCTION postgresto.set_audit_user()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  v_claims text;
  v_login text;
BEGIN
  v_claims := current_setting('request.jwt.claims', true);
  IF v_claims IS NOT NULL AND btrim(v_claims) <> '' THEN
    BEGIN
      v_login := btrim(v_claims::json ->> 'preferred_username');
    EXCEPTION
      WHEN others THEN
        v_login := NULL;
    END;
    IF v_login = '' THEN
      v_login := NULL;
    END IF;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF v_login IS NOT NULL THEN
      NEW.created_by := v_login;
      NEW.updated_by := v_login;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.created_by := OLD.created_by;
    IF v_login IS NOT NULL THEN
      NEW.updated_by := v_login;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;
