--
-- PostgreSQL database dump
--

-- Dumped from database version 10.15
-- Dumped by pg_dump version 13.1

-- Started on 2021-07-02 12:07:15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 14 (class 2615 OID 1168990)
-- Name: pkg_rpn_util; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pkg_rpn_util;


ALTER SCHEMA pkg_rpn_util OWNER TO postgres;

--
-- TOC entry 8540 (class 0 OID 0)
-- Dependencies: 14
-- Name: SCHEMA pkg_rpn_util; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA pkg_rpn_util IS 'Калькулятор. Сильно упрощенная реализация пакета rpn_util в ORACLE.';


--
-- TOC entry 1846 (class 1255 OID 1171565)
-- Name: eval(character varying); Type: FUNCTION; Schema: pkg_rpn_util; Owner: postgres
--

CREATE FUNCTION pkg_rpn_util.eval(p_formula character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION pkg_rpn_util.eval(p_formula character varying) OWNER TO postgres;

--
-- TOC entry 8541 (class 0 OID 0)
-- Dependencies: 1846
-- Name: FUNCTION eval(p_formula character varying); Type: COMMENT; Schema: pkg_rpn_util; Owner: postgres
--

COMMENT ON FUNCTION pkg_rpn_util.eval(p_formula character varying) IS 'Калькулятор. Возвращает значение выражения.';


--
-- TOC entry 1845 (class 1255 OID 1168991)
-- Name: is_numeric(character varying); Type: FUNCTION; Schema: pkg_rpn_util; Owner: postgres
--

CREATE FUNCTION pkg_rpn_util.is_numeric(p_val character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
    res numeric;
begin
    res := p_val::numeric;
    return true;
exception 
    when others then
        return false;
end; 
$$;


ALTER FUNCTION pkg_rpn_util.is_numeric(p_val character varying) OWNER TO postgres;

--
-- TOC entry 8542 (class 0 OID 0)
-- Dependencies: 1845
-- Name: FUNCTION is_numeric(p_val character varying); Type: COMMENT; Schema: pkg_rpn_util; Owner: postgres
--

COMMENT ON FUNCTION pkg_rpn_util.is_numeric(p_val character varying) IS 'Возвращает является ли заданный параметр числовым.';


--
-- TOC entry 1810 (class 1255 OID 1171644)
-- Name: parse(character varying, character varying[]); Type: FUNCTION; Schema: pkg_rpn_util; Owner: postgres
--

CREATE FUNCTION pkg_rpn_util.parse(p_formula character varying, p_vars character varying[]) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
    formula character varying(255);
    vars character varying(255)[];
    var character varying(255)[];
    var_name character varying(255);
    var_val character varying(255);
    vfound boolean;
    reserved_words constant character varying(255)[5] := array['cos', 'sin', 'tan', 'cot', 'pi'];
begin
    if p_formula is null or p_vars is null then
        raise exception using
            errcode = 'PARNL',
            message = 'Function parameters not specified',
            hint = 'Function parameters not specified';  
    end if;
    
    vars := p_vars;
    
    foreach var_name in array regexp_split_to_array(p_formula, '[^[:alnum:]_]')
    loop
        vfound := false;
        if var_name <> '' and not pkg_rpn_util.is_numeric(var_name) and array_position(reserved_words, var_name) is null then
            foreach var slice 1 in array vars
            loop
                if var_name = var[1] then
                    vfound := true;
                    exit;
                end if;
            end loop;
            if not vfound then
                raise exception using
                    errcode = 'VARNP',
                    message = 'Variable "' || var_name || '" is not found in function params',
                    hint = 'Variable "' || var_name || '" is not found in function params';      
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
$$;


ALTER FUNCTION pkg_rpn_util.parse(p_formula character varying, p_vars character varying[]) OWNER TO postgres;

--
-- TOC entry 8543 (class 0 OID 0)
-- Dependencies: 1810
-- Name: FUNCTION parse(p_formula character varying, p_vars character varying[]); Type: COMMENT; Schema: pkg_rpn_util; Owner: postgres
--

COMMENT ON FUNCTION pkg_rpn_util.parse(p_formula character varying, p_vars character varying[]) IS 'Парсер формулы, выражения. Возвращает проанализированное выражение с подставленными в него значениями переменных.';


-- Completed on 2021-07-02 12:07:28

--
-- PostgreSQL database dump complete
--

