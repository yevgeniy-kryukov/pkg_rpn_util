-- FUNCTION: pkg_rpn_util.eval(character varying)

-- DROP FUNCTION IF EXISTS pkg_rpn_util.eval(character varying);

CREATE OR REPLACE FUNCTION pkg_rpn_util.eval(
	p_formula character varying)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    res numeric;
begin
    if p_formula is null then 
        raise exception using
            errcode = 'PARNL',
            message = 'Function parameters not specified',
            hint = 'Function parameters not specified';
    end if;
    execute 'select ' || p_formula into res;
    return res;
exception 
    when division_by_zero or sqlstate 'PARNL' then
        return null;
    when others then
        raise;
end;
$BODY$;

ALTER FUNCTION pkg_rpn_util.eval(character varying)
    OWNER TO postgres;

COMMENT ON FUNCTION pkg_rpn_util.eval(character varying)
    IS 'Калькулятор. Возвращает значение выражения.';
