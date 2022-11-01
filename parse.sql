-- FUNCTION: pkg_rpn_util.parse(character varying, character varying[])

-- DROP FUNCTION IF EXISTS pkg_rpn_util.parse(character varying, character varying[]);

CREATE OR REPLACE FUNCTION pkg_rpn_util.parse(
	p_formula character varying,
	p_vars character varying[])
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    formula character varying(255);
    vars character varying(255)[];
    var character varying(255)[];
    var_name character varying(255);
    var_val character varying(255);
    vfound boolean;
    reserved_words constant character varying(255)[5] := array['cos', 'sin', 'tan', 'cot', 'pi'];
    r record;
begin
    if p_formula is null or p_vars is null then
        raise exception using
            errcode = 'PARNL',
            message = 'Function parameters not specified',
            hint = 'Function parameters not specified';  
    end if;
    
    vars := p_vars;
    
    for r in (select (regexp_matches(p_formula, '\m[a-z]+\d*', 'gi'))[1] as var_name) 
    loop
        vfound := false;
        if array_position(reserved_words, r.var_name) is null then
            foreach var slice 1 in array vars
            loop
                if r.var_name = var[1] then
                    vfound := true;
                    exit;
                end if;
            end loop;
            if not vfound then
                raise exception using
                    errcode = 'VARNP',
                    message = 'Variable "' || r.var_name || '" is not found in function params',
                    hint = 'Variable "' || r.var_name || '" is not found in function params';      
            end if;
        end if;
    end loop;
    
    formula := p_formula;
    foreach var slice 1 in array vars
    loop
        var_name := var[1];
        var_val := var[2];
        if var_val is null then
            return null;
        end if;       
        if var_val <> '' and not pkg_rpn_util.is_numeric(var_val) then
             raise exception using
                errcode = 'VARNN',
                message = 'The value of the expression variable is not numeric',
                hint = 'The value of the expression variable is not numeric';           
        end if;
        perform regexp_matches(formula, '\m' || var_name || '\M', 'gi');
        if found then
            formula := regexp_replace(formula, '\m' || var_name || '\M', var_val||'::numeric', 'gi'); 
        else
            raise exception using
                errcode = 'VARNF',
                message = 'Expression variable "' || var_name || '" not found in formula ' ||  coalesce(formula, 'null'),
                hint = 'Expression variable "' || var_name || '" not found in formula ' ||  coalesce(formula, 'null');
        end if;
    end loop;
    return formula;
exception 
    when sqlstate 'VARNP' or sqlstate 'PARNL' then  -- в Оракле не выбрасывается исключительная ситуация, делаем как там
        return null;
    when others then 
        raise;
end;
$BODY$;

ALTER FUNCTION pkg_rpn_util.parse(character varying, character varying[])
    OWNER TO postgres;

COMMENT ON FUNCTION pkg_rpn_util.parse(character varying, character varying[])
    IS 'Парсер формулы, выражения. Возвращает проанализированное выражение с подставленными в него значениями переменных.';
