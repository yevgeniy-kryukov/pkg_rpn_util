-- FUNCTION: pkg_rpn_util.is_numeric(character varying)

-- DROP FUNCTION IF EXISTS pkg_rpn_util.is_numeric(character varying);

CREATE OR REPLACE FUNCTION pkg_rpn_util.is_numeric(
	p_val character varying)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    res numeric;
begin
    res := p_val::numeric;
    return true;
exception 
    when others then
        return false;
end; 
$BODY$;

ALTER FUNCTION pkg_rpn_util.is_numeric(character varying)
    OWNER TO postgres;

COMMENT ON FUNCTION pkg_rpn_util.is_numeric(character varying)
    IS 'Возвращает является ли заданный параметр числовым.';
