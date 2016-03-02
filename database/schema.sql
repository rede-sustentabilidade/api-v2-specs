--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: 1; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA "1";


--
-- Name: rs; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA rs;


--
-- Name: sqitch; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sqitch;


--
-- Name: SCHEMA sqitch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA sqitch IS 'Sqitch database deployment metadata v1.0.';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: access_level_kind; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE access_level_kind AS ENUM (
    'municipal',
    'estadual',
    'nacional'
);


--
-- Name: all_rs_roles(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION all_rs_roles() RETURNS name[]
    LANGUAGE sql
    AS $$
          SELECT array_agg(rolname)
          FROM pg_roles
          WHERE rolname ~ 'rs_role_.*';
       $$;


--
-- Name: can_access_with_roles(name[], integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION can_access_with_roles(role_names name[], cid integer, sid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
          BEGIN
            -- if user not have any role should return false
            IF NOT (SELECT (current_user_roles() && role_names)) THEN
               RETURN false;
            END IF;

            -- if has nacional access should return true
            IF current_user_max_access_level_for_roles(role_names) = 'nacional'::access_level_kind THEN
               RETURN true;
            END IF;

            -- if user has access to state
            IF current_user_max_access_level_for_roles_region(role_names, null, sid)  >= 'estadual'::access_level_kind THEN
               RETURN true;
            END IF;

            -- if user has access to city
            IF current_user_max_access_level_for_roles_region(role_names, cid, null)  >= 'municipal'::access_level_kind THEN
               RETURN true;
            END IF;

            RETURN false;
          END;
       $$;


--
-- Name: current_user_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION current_user_id() RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN nullif(current_setting('postgrest.claims.user_id'), '')::integer;
EXCEPTION WHEN others THEN 
SET postgrest.claims.user_id TO '';
RETURN NULL::integer;
END
$$;


--
-- Name: current_user_max_access_level_for_roles(name[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION current_user_max_access_level_for_roles(role_names name[]) RETURNS access_level_kind
    LANGUAGE sql
    AS $$
          SELECT max(access_level)::access_level_kind
          FROM rs.regra_afiliados 
          WHERE user_id = current_user_id()
          AND role_name = ANY(role_names);
       $$;


--
-- Name: current_user_max_access_level_for_roles_region(name[], integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION current_user_max_access_level_for_roles_region(role_names name[], cid integer, sid integer) RETURNS access_level_kind
    LANGUAGE sql
    AS $$
          SELECT max(access_level)::access_level_kind
          FROM rs.regra_afiliados 
          WHERE user_id = current_user_id()
          AND role_name = ANY(role_names)
          AND (state_id = sid OR city_id = cid);
       $$;


--
-- Name: current_user_roles(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION current_user_roles() RETURNS name[]
    LANGUAGE sql
    AS $$
          SELECT array_agg(DISTINCT role_name) 
          FROM rs.regra_afiliados 
          WHERE user_id = current_user_id();
       $$;


--
-- Name: is_owner_or_admin(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_owner_or_admin(bigint) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
          SELECT
          current_user_id() = $1
          OR current_user = ANY(ARRAY['rs_role_admin_master', 'admin']);
       $_$;


SET search_path = rs, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: afiliados; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE afiliados (
    user_id bigint NOT NULL,
    birthday date NOT NULL,
    nome_mae character varying(255),
    nacionalidade character varying(255),
    cep character varying(9),
    endereco character varying(255),
    bairro character varying(255),
    cidade character varying(255),
    uf character varying(255),
    telefone_residencial character varying(255),
    telefone_celular character varying(255),
    telefone_comercial character varying(255),
    contribuicao numeric(10,2),
    titulo_eleitoral character varying(12),
    zona_eleitoral character varying(3),
    secao_eleitoral character varying(4),
    cpf character varying(11),
    ativista character varying(255),
    escolaridade character varying(255),
    local_trabalho character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    numero character varying(255),
    complemento character varying(255),
    filiado_outros_quais character varying(255),
    cadidatura_quais character varying(255),
    cargo_eletivo_quais character varying(255),
    cargo_confianca_quais character varying(255),
    ativista_quais character varying(255),
    status character varying(255),
    candidato_cargo character varying(255),
    candidato_motivo text,
    candidato_base text,
    candidato_estatuto text,
    candidato_antecedentes text,
    filiado_partido_quais text,
    foi_candidato_quais text,
    atual_anterior_eleito_quais text,
    leu_manifesto character varying(1),
    sexo character varying(1),
    "tipo_Filiacao" character varying(1),
    quer_ser_candidato character varying(1),
    filiado_partido character varying(1),
    foi_candidato character varying(1),
    atual_anterior_eleito character varying(1),
    cargo_confianca character varying(1),
    voluntario character varying(1),
    leu_estatuto character varying(1),
    quem_abonou bigint,
    quando_abonou date,
    nome character varying(255),
    email character varying(255),
    fullname character varying(255),
    filiaweb boolean DEFAULT false,
    cidade_id integer,
    estado_id integer
);


SET search_path = "1", pg_catalog;

--
-- Name: filiados; Type: VIEW; Schema: 1; Owner: -
--

CREATE VIEW filiados AS
 SELECT a.user_id,
    a.birthday,
    a.nome_mae,
    a.nacionalidade,
    a.cep,
    a.endereco,
    a.bairro,
    a.cidade,
    a.uf,
    a.telefone_residencial,
    a.telefone_celular,
    a.telefone_comercial,
    a.contribuicao,
    a.titulo_eleitoral,
    a.zona_eleitoral,
    a.secao_eleitoral,
    a.cpf,
    a.ativista,
    a.escolaridade,
    a.local_trabalho,
    a.created_at,
    a.updated_at,
    a.numero,
    a.complemento,
    a.filiado_outros_quais,
    a.cadidatura_quais,
    a.cargo_eletivo_quais,
    a.cargo_confianca_quais,
    a.ativista_quais,
    a.status,
    a.candidato_cargo,
    a.candidato_motivo,
    a.candidato_base,
    a.candidato_estatuto,
    a.candidato_antecedentes,
    a.filiado_partido_quais,
    a.foi_candidato_quais,
    a.atual_anterior_eleito_quais,
    a.leu_manifesto,
    a.sexo,
    a.quer_ser_candidato,
    a.filiado_partido,
    a.foi_candidato,
    a.atual_anterior_eleito,
    a.cargo_confianca,
    a.voluntario,
    a.leu_estatuto,
    a.quem_abonou,
    a.quando_abonou,
    a.nome,
    a.email,
    a.fullname,
    a.filiaweb
   FROM rs.afiliados a
  WHERE (public.can_access_with_roles(public.all_rs_roles(), a.cidade_id, a.estado_id) OR public.is_owner_or_admin(a.user_id));


SET search_path = public, pg_catalog;

--
-- Name: goose_db_version; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE goose_db_version (
    id integer NOT NULL,
    version_id bigint NOT NULL,
    is_applied boolean NOT NULL,
    tstamp timestamp without time zone DEFAULT now()
);


--
-- Name: goose_db_version_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE goose_db_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: goose_db_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE goose_db_version_id_seq OWNED BY goose_db_version.id;


--
-- Name: regra_afiliados_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE regra_afiliados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET search_path = rs, pg_catalog;

--
-- Name: LinkAfiliadoInteresse; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE "LinkAfiliadoInteresse" (
    id_afiliado bigint NOT NULL,
    "id_areaInteresse" bigint NOT NULL
);


--
-- Name: LinkAtuacaoProfissional; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE "LinkAtuacaoProfissional" (
    id_filiado bigint NOT NULL,
    id_area bigint NOT NULL
);


--
-- Name: afiliados_user_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE afiliados_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: afiliados_user_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE afiliados_user_id_seq OWNED BY afiliados.user_id;


--
-- Name: areasInteresse; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE "areasInteresse" (
    id bigint NOT NULL,
    area_interesse character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
);


--
-- Name: areasInteresse_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE "areasInteresse_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: areasInteresse_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE "areasInteresse_id_seq" OWNED BY "areasInteresse".id;


--
-- Name: atuacoesProfissionais; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE "atuacoesProfissionais" (
    id bigint NOT NULL,
    area_atuacao character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
);


--
-- Name: atuacoesProfissionais_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE "atuacoesProfissionais_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: atuacoesProfissionais_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE "atuacoesProfissionais_id_seq" OWNED BY "atuacoesProfissionais".id;


--
-- Name: cidades; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE cidades (
    id integer NOT NULL,
    estado_id integer NOT NULL,
    codigo integer,
    nome text NOT NULL,
    uf text NOT NULL
);


--
-- Name: cms; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE cms (
    id bigint NOT NULL,
    titulo character varying(255) NOT NULL,
    texto character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
);


--
-- Name: cms_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE cms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cms_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE cms_id_seq OWNED BY cms.id;


--
-- Name: dados_contribuicoes; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE dados_contribuicoes (
    user_id bigint NOT NULL,
    tipo character varying(255) NOT NULL,
    cartao_nome character varying(255),
    cartao_numero character varying(255),
    cartao_validade_mes character varying(255),
    cartao_validade_ano character varying(255),
    cartao_codigo_verificacao character varying(255),
    nome_titular character varying(255),
    agencia character varying(255),
    banco character varying(255),
    numero_conta character varying(255),
    created_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    bandeira character varying(255),
    verificado smallint
);


--
-- Name: doacoes; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE doacoes (
    id bigint NOT NULL,
    user_id bigint,
    quantia numeric(12,2) NOT NULL,
    forma integer NOT NULL,
    nome character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    endereco character varying(255) NOT NULL,
    numero character varying(255) NOT NULL,
    complemento character varying(255) NOT NULL,
    bairro character varying(255) NOT NULL,
    cidade character varying(255) NOT NULL,
    estado character varying(255) NOT NULL,
    cep character varying(255) NOT NULL,
    pais character varying(255) NOT NULL,
    telefone character varying(255) NOT NULL,
    transacao character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
);


--
-- Name: doacoes_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE doacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doacoes_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE doacoes_id_seq OWNED BY doacoes.id;


--
-- Name: estados; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE estados (
    id integer NOT NULL,
    nome text NOT NULL,
    uf text NOT NULL,
    regiao text NOT NULL
);


--
-- Name: filiaweb_csv; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE filiaweb_csv (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    file_text text,
    file_name text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: filiaweb_csv_logs; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE filiaweb_csv_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    filiaweb_csv_id uuid NOT NULL,
    email text NOT NULL,
    found boolean NOT NULL,
    name text
);


--
-- Name: impugnacoes; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE impugnacoes (
    id bigint NOT NULL,
    impugnado bigint NOT NULL,
    quem_impugnou bigint NOT NULL,
    motivo text NOT NULL,
    data date NOT NULL,
    created_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
);


--
-- Name: impugnacoes_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE impugnacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: impugnacoes_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE impugnacoes_id_seq OWNED BY impugnacoes.id;


--
-- Name: migrations; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE migrations (
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


--
-- Name: notificacoes; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE notificacoes (
    id bigint NOT NULL,
    titulo character varying(255) NOT NULL,
    categoria character varying(255) NOT NULL,
    data date NOT NULL,
    imagem_destaque character varying(255),
    texto character varying(255) NOT NULL,
    link_agir_agora character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    label_agir_agora character varying(255) NOT NULL
);


--
-- Name: notificacoes_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE notificacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notificacoes_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE notificacoes_id_seq OWNED BY notificacoes.id;


--
-- Name: notificacoes_usuario; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE notificacoes_usuario (
    user_id integer NOT NULL,
    notificacao_id bigint NOT NULL
);


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE oauth_access_tokens (
    access_token text NOT NULL,
    client_id text NOT NULL,
    user_id uuid NOT NULL,
    expires timestamp without time zone NOT NULL
);


--
-- Name: oauth_authorization_codes; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE oauth_authorization_codes (
    code text NOT NULL,
    client_id text NOT NULL,
    user_id uuid NOT NULL,
    redirect_uri text
);


--
-- Name: oauth_clients; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE oauth_clients (
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    redirect_uri text NOT NULL
);


--
-- Name: oauth_refresh_tokens; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE oauth_refresh_tokens (
    refresh_token text NOT NULL,
    client_id text NOT NULL,
    user_id uuid NOT NULL,
    expires timestamp without time zone NOT NULL
);


--
-- Name: payments; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE payments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    success smallint NOT NULL,
    order_id character(36),
    transaction_id character(36),
    amount bigint,
    method smallint,
    number character(4),
    oper_transaction_id character varying(50),
    auth_code character varying(50),
    return_code character varying(10),
    return_message text,
    proof character varying(50),
    status smallint,
    error_code character varying(10),
    error_message text,
    captured smallint,
    call smallint,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    boleto_number character varying(50),
    boleto_vencimento date,
    boleto_url text,
    boleto_barcode character varying(100)
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE payments_id_seq OWNED BY payments.id;


--
-- Name: regra_afiliados; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE regra_afiliados (
    id bigint DEFAULT nextval('public.regra_afiliados_id_seq'::regclass) NOT NULL,
    role_name name NOT NULL,
    access_level public.access_level_kind NOT NULL,
    user_id bigint,
    city_id integer,
    state_id integer
);


--
-- Name: socialnetw; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE socialnetw (
    id bigint NOT NULL,
    id_user bigint NOT NULL,
    credenciador character varying(11) NOT NULL,
    credenciais character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
    obj_enviado text
);


--
-- Name: socialnetw_id_seq; Type: SEQUENCE; Schema: rs; Owner: -
--

CREATE SEQUENCE socialnetw_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: socialnetw_id_seq; Type: SEQUENCE OWNED BY; Schema: rs; Owner: -
--

ALTER SEQUENCE socialnetw_id_seq OWNED BY socialnetw.id;


--
-- Name: users; Type: TABLE; Schema: rs; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    username text NOT NULL,
    password text NOT NULL
);


SET search_path = sqitch, pg_catalog;

--
-- Name: changes; Type: TABLE; Schema: sqitch; Owner: -; Tablespace: 
--

CREATE TABLE changes (
    change_id text NOT NULL,
    script_hash text,
    change text NOT NULL,
    project text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL
);


--
-- Name: TABLE changes; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON TABLE changes IS 'Tracks the changes currently deployed to the database.';


--
-- Name: COLUMN changes.change_id; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.change_id IS 'Change primary key.';


--
-- Name: COLUMN changes.script_hash; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.script_hash IS 'Deploy script SHA-1 hash.';


--
-- Name: COLUMN changes.change; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.change IS 'Name of a deployed change.';


--
-- Name: COLUMN changes.project; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.project IS 'Name of the Sqitch project to which the change belongs.';


--
-- Name: COLUMN changes.note; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.note IS 'Description of the change.';


--
-- Name: COLUMN changes.committed_at; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.committed_at IS 'Date the change was deployed.';


--
-- Name: COLUMN changes.committer_name; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.committer_name IS 'Name of the user who deployed the change.';


--
-- Name: COLUMN changes.committer_email; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.committer_email IS 'Email address of the user who deployed the change.';


--
-- Name: COLUMN changes.planned_at; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.planned_at IS 'Date the change was added to the plan.';


--
-- Name: COLUMN changes.planner_name; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.planner_name IS 'Name of the user who planed the change.';


--
-- Name: COLUMN changes.planner_email; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN changes.planner_email IS 'Email address of the user who planned the change.';


--
-- Name: dependencies; Type: TABLE; Schema: sqitch; Owner: -; Tablespace: 
--

CREATE TABLE dependencies (
    change_id text NOT NULL,
    type text NOT NULL,
    dependency text NOT NULL,
    dependency_id text,
    CONSTRAINT dependencies_check CHECK ((((type = 'require'::text) AND (dependency_id IS NOT NULL)) OR ((type = 'conflict'::text) AND (dependency_id IS NULL))))
);


--
-- Name: TABLE dependencies; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON TABLE dependencies IS 'Tracks the currently satisfied dependencies.';


--
-- Name: COLUMN dependencies.change_id; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN dependencies.change_id IS 'ID of the depending change.';


--
-- Name: COLUMN dependencies.type; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN dependencies.type IS 'Type of dependency.';


--
-- Name: COLUMN dependencies.dependency; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN dependencies.dependency IS 'Dependency name.';


--
-- Name: COLUMN dependencies.dependency_id; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN dependencies.dependency_id IS 'Change ID the dependency resolves to.';


--
-- Name: events; Type: TABLE; Schema: sqitch; Owner: -; Tablespace: 
--

CREATE TABLE events (
    event text NOT NULL,
    change_id text NOT NULL,
    change text NOT NULL,
    project text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    requires text[] DEFAULT '{}'::text[] NOT NULL,
    conflicts text[] DEFAULT '{}'::text[] NOT NULL,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL,
    CONSTRAINT events_event_check CHECK ((event = ANY (ARRAY['deploy'::text, 'revert'::text, 'fail'::text, 'merge'::text])))
);


--
-- Name: TABLE events; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON TABLE events IS 'Contains full history of all deployment events.';


--
-- Name: COLUMN events.event; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.event IS 'Type of event.';


--
-- Name: COLUMN events.change_id; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.change_id IS 'Change ID.';


--
-- Name: COLUMN events.change; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.change IS 'Change name.';


--
-- Name: COLUMN events.project; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.project IS 'Name of the Sqitch project to which the change belongs.';


--
-- Name: COLUMN events.note; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.note IS 'Description of the change.';


--
-- Name: COLUMN events.requires; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.requires IS 'Array of the names of required changes.';


--
-- Name: COLUMN events.conflicts; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.conflicts IS 'Array of the names of conflicting changes.';


--
-- Name: COLUMN events.tags; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.tags IS 'Tags associated with the change.';


--
-- Name: COLUMN events.committed_at; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.committed_at IS 'Date the event was committed.';


--
-- Name: COLUMN events.committer_name; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.committer_name IS 'Name of the user who committed the event.';


--
-- Name: COLUMN events.committer_email; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.committer_email IS 'Email address of the user who committed the event.';


--
-- Name: COLUMN events.planned_at; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.planned_at IS 'Date the event was added to the plan.';


--
-- Name: COLUMN events.planner_name; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.planner_name IS 'Name of the user who planed the change.';


--
-- Name: COLUMN events.planner_email; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN events.planner_email IS 'Email address of the user who plan planned the change.';


--
-- Name: projects; Type: TABLE; Schema: sqitch; Owner: -; Tablespace: 
--

CREATE TABLE projects (
    project text NOT NULL,
    uri text,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    creator_name text NOT NULL,
    creator_email text NOT NULL
);


--
-- Name: TABLE projects; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON TABLE projects IS 'Sqitch projects deployed to this database.';


--
-- Name: COLUMN projects.project; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN projects.project IS 'Unique Name of a project.';


--
-- Name: COLUMN projects.uri; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN projects.uri IS 'Optional project URI';


--
-- Name: COLUMN projects.created_at; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN projects.created_at IS 'Date the project was added to the database.';


--
-- Name: COLUMN projects.creator_name; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN projects.creator_name IS 'Name of the user who added the project.';


--
-- Name: COLUMN projects.creator_email; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN projects.creator_email IS 'Email address of the user who added the project.';


--
-- Name: releases; Type: TABLE; Schema: sqitch; Owner: -; Tablespace: 
--

CREATE TABLE releases (
    version real NOT NULL,
    installed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    installer_name text NOT NULL,
    installer_email text NOT NULL
);


--
-- Name: TABLE releases; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON TABLE releases IS 'Sqitch registry releases.';


--
-- Name: COLUMN releases.version; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN releases.version IS 'Version of the Sqitch registry.';


--
-- Name: COLUMN releases.installed_at; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN releases.installed_at IS 'Date the registry release was installed.';


--
-- Name: COLUMN releases.installer_name; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN releases.installer_name IS 'Name of the user who installed the registry release.';


--
-- Name: COLUMN releases.installer_email; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN releases.installer_email IS 'Email address of the user who installed the registry release.';


--
-- Name: tags; Type: TABLE; Schema: sqitch; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    tag_id text NOT NULL,
    tag text NOT NULL,
    project text NOT NULL,
    change_id text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL
);


--
-- Name: TABLE tags; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON TABLE tags IS 'Tracks the tags currently applied to the database.';


--
-- Name: COLUMN tags.tag_id; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.tag_id IS 'Tag primary key.';


--
-- Name: COLUMN tags.tag; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.tag IS 'Project-unique tag name.';


--
-- Name: COLUMN tags.project; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.project IS 'Name of the Sqitch project to which the tag belongs.';


--
-- Name: COLUMN tags.change_id; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.change_id IS 'ID of last change deployed before the tag was applied.';


--
-- Name: COLUMN tags.note; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.note IS 'Description of the tag.';


--
-- Name: COLUMN tags.committed_at; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.committed_at IS 'Date the tag was applied to the database.';


--
-- Name: COLUMN tags.committer_name; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.committer_name IS 'Name of the user who applied the tag.';


--
-- Name: COLUMN tags.committer_email; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.committer_email IS 'Email address of the user who applied the tag.';


--
-- Name: COLUMN tags.planned_at; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.planned_at IS 'Date the tag was added to the plan.';


--
-- Name: COLUMN tags.planner_name; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.planner_name IS 'Name of the user who planed the tag.';


--
-- Name: COLUMN tags.planner_email; Type: COMMENT; Schema: sqitch; Owner: -
--

COMMENT ON COLUMN tags.planner_email IS 'Email address of the user who planned the tag.';


SET search_path = public, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY goose_db_version ALTER COLUMN id SET DEFAULT nextval('goose_db_version_id_seq'::regclass);


SET search_path = rs, pg_catalog;

--
-- Name: user_id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY afiliados ALTER COLUMN user_id SET DEFAULT nextval('afiliados_user_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY "areasInteresse" ALTER COLUMN id SET DEFAULT nextval('"areasInteresse_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY "atuacoesProfissionais" ALTER COLUMN id SET DEFAULT nextval('"atuacoesProfissionais_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY cms ALTER COLUMN id SET DEFAULT nextval('cms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY doacoes ALTER COLUMN id SET DEFAULT nextval('doacoes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY impugnacoes ALTER COLUMN id SET DEFAULT nextval('impugnacoes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY notificacoes ALTER COLUMN id SET DEFAULT nextval('notificacoes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY payments ALTER COLUMN id SET DEFAULT nextval('payments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: rs; Owner: -
--

ALTER TABLE ONLY socialnetw ALTER COLUMN id SET DEFAULT nextval('socialnetw_id_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- Name: goose_db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY goose_db_version
    ADD CONSTRAINT goose_db_version_pkey PRIMARY KEY (id);


SET search_path = rs, pg_catalog;

--
-- Name: LinkAfiliadoInteresse_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY "LinkAfiliadoInteresse"
    ADD CONSTRAINT "LinkAfiliadoInteresse_pkey" PRIMARY KEY (id_afiliado, "id_areaInteresse");


--
-- Name: LinkAtuacaoProfissional_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY "LinkAtuacaoProfissional"
    ADD CONSTRAINT "LinkAtuacaoProfissional_pkey" PRIMARY KEY (id_filiado, id_area);


--
-- Name: afiliados_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY afiliados
    ADD CONSTRAINT afiliados_pkey PRIMARY KEY (user_id);


--
-- Name: areasInteresse_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY "areasInteresse"
    ADD CONSTRAINT "areasInteresse_pkey" PRIMARY KEY (id);


--
-- Name: atuacoesProfissionais_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY "atuacoesProfissionais"
    ADD CONSTRAINT "atuacoesProfissionais_pkey" PRIMARY KEY (id);


--
-- Name: cidades_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cidades
    ADD CONSTRAINT cidades_pkey PRIMARY KEY (id);


--
-- Name: cms_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cms
    ADD CONSTRAINT cms_pkey PRIMARY KEY (id);


--
-- Name: dados_contribuicoes_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dados_contribuicoes
    ADD CONSTRAINT dados_contribuicoes_pkey PRIMARY KEY (user_id);


--
-- Name: doacoes_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY doacoes
    ADD CONSTRAINT doacoes_pkey PRIMARY KEY (id);


--
-- Name: estados_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY estados
    ADD CONSTRAINT estados_pkey PRIMARY KEY (id);


--
-- Name: filiaweb_csv_logs_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY filiaweb_csv_logs
    ADD CONSTRAINT filiaweb_csv_logs_pkey PRIMARY KEY (id);


--
-- Name: filiaweb_csv_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY filiaweb_csv
    ADD CONSTRAINT filiaweb_csv_pkey PRIMARY KEY (id);


--
-- Name: impugnacoes_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY impugnacoes
    ADD CONSTRAINT impugnacoes_pkey PRIMARY KEY (id);


--
-- Name: notificacoes_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notificacoes
    ADD CONSTRAINT notificacoes_pkey PRIMARY KEY (id);


--
-- Name: notificacoes_usuario_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notificacoes_usuario
    ADD CONSTRAINT notificacoes_usuario_pkey PRIMARY KEY (user_id, notificacao_id);


--
-- Name: oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (access_token);


--
-- Name: oauth_clients_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (client_id, client_secret);


--
-- Name: oauth_refresh_tokens_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_refresh_tokens
    ADD CONSTRAINT oauth_refresh_tokens_pkey PRIMARY KEY (refresh_token);


--
-- Name: payments_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: regra_afiliados_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY regra_afiliados
    ADD CONSTRAINT regra_afiliados_pkey PRIMARY KEY (id);


--
-- Name: socialnetw_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY socialnetw
    ADD CONSTRAINT socialnetw_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: rs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


SET search_path = sqitch, pg_catalog;

--
-- Name: changes_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY changes
    ADD CONSTRAINT changes_pkey PRIMARY KEY (change_id);


--
-- Name: changes_project_script_hash_key; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY changes
    ADD CONSTRAINT changes_project_script_hash_key UNIQUE (project, script_hash);


--
-- Name: dependencies_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dependencies
    ADD CONSTRAINT dependencies_pkey PRIMARY KEY (change_id, dependency);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (change_id, committed_at);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project);


--
-- Name: projects_uri_key; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_uri_key UNIQUE (uri);


--
-- Name: releases_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (version);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (tag_id);


--
-- Name: tags_project_tag_key; Type: CONSTRAINT; Schema: sqitch; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_project_tag_key UNIQUE (project, tag);


SET search_path = rs, pg_catalog;

--
-- Name: afiliados_region_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX afiliados_region_idx ON afiliados USING btree (user_id, cidade_id, estado_id);


--
-- Name: cidades_order_asc; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX cidades_order_asc ON cidades USING btree (nome);


--
-- Name: cidades_uf; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX cidades_uf ON cidades USING btree (uf);


--
-- Name: regra_afiliados_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX regra_afiliados_idx ON regra_afiliados USING btree (user_id, role_name, access_level, city_id, state_id);


--
-- Name: role_aclv_user_uix; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX role_aclv_user_uix ON regra_afiliados USING btree (user_id, access_level, role_name);


--
-- Name: rs_migrate_LinkAfiliadoInteresse_id_areaInteresse1_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX "rs_migrate_LinkAfiliadoInteresse_id_areaInteresse1_idx" ON "LinkAfiliadoInteresse" USING btree ("id_areaInteresse");


--
-- Name: rs_migrate_LinkAtuacaoProfissional_id_area1_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX "rs_migrate_LinkAtuacaoProfissional_id_area1_idx" ON "LinkAtuacaoProfissional" USING btree (id_area);


--
-- Name: rs_migrate_afiliados_quem_abonou1_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX rs_migrate_afiliados_quem_abonou1_idx ON afiliados USING btree (quem_abonou);


--
-- Name: rs_migrate_impugnacoes_impugnado1_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX rs_migrate_impugnacoes_impugnado1_idx ON impugnacoes USING btree (impugnado);


--
-- Name: rs_migrate_impugnacoes_quem_impugnou2_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX rs_migrate_impugnacoes_quem_impugnou2_idx ON impugnacoes USING btree (quem_impugnou);


--
-- Name: rs_migrate_socialnetw_credenciador2_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX rs_migrate_socialnetw_credenciador2_idx ON socialnetw USING btree (credenciador, credenciais);


--
-- Name: rs_migrate_socialnetw_id_user1_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX rs_migrate_socialnetw_id_user1_idx ON socialnetw USING btree (id_user, credenciador);


--
-- Name: unique_uf_idx; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_uf_idx ON estados USING btree (uf);


--
-- Name: users_username_password; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE INDEX users_username_password ON users USING btree (username, password);


--
-- Name: users_username_unique; Type: INDEX; Schema: rs; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_username_unique ON users USING btree (username);


--
-- Name: afiliados_cidade_id_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY afiliados
    ADD CONSTRAINT afiliados_cidade_id_fkey FOREIGN KEY (cidade_id) REFERENCES cidades(id);


--
-- Name: afiliados_estado_id_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY afiliados
    ADD CONSTRAINT afiliados_estado_id_fkey FOREIGN KEY (estado_id) REFERENCES estados(id);


--
-- Name: afiliados_quem_abonou_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY afiliados
    ADD CONSTRAINT afiliados_quem_abonou_fkey FOREIGN KEY (quem_abonou) REFERENCES afiliados(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: cidades_estado_id_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY cidades
    ADD CONSTRAINT cidades_estado_id_fkey FOREIGN KEY (estado_id) REFERENCES estados(id);


--
-- Name: dados_contribuicoes_user_id_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY dados_contribuicoes
    ADD CONSTRAINT dados_contribuicoes_user_id_fkey FOREIGN KEY (user_id) REFERENCES afiliados(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: filiaweb_csv_logs_filiaweb_csv_id_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY filiaweb_csv_logs
    ADD CONSTRAINT filiaweb_csv_logs_filiaweb_csv_id_fkey FOREIGN KEY (filiaweb_csv_id) REFERENCES filiaweb_csv(id);


--
-- Name: impugnacoes_impugnado_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY impugnacoes
    ADD CONSTRAINT impugnacoes_impugnado_fkey FOREIGN KEY (impugnado) REFERENCES afiliados(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: impugnacoes_quem_impugnou_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY impugnacoes
    ADD CONSTRAINT impugnacoes_quem_impugnou_fkey FOREIGN KEY (quem_impugnou) REFERENCES afiliados(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: regra_afiliados_user_id_fkey; Type: FK CONSTRAINT; Schema: rs; Owner: -
--

ALTER TABLE ONLY regra_afiliados
    ADD CONSTRAINT regra_afiliados_user_id_fkey FOREIGN KEY (user_id) REFERENCES afiliados(user_id);


SET search_path = sqitch, pg_catalog;

--
-- Name: changes_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: -
--

ALTER TABLE ONLY changes
    ADD CONSTRAINT changes_project_fkey FOREIGN KEY (project) REFERENCES projects(project) ON UPDATE CASCADE;


--
-- Name: dependencies_change_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: -
--

ALTER TABLE ONLY dependencies
    ADD CONSTRAINT dependencies_change_id_fkey FOREIGN KEY (change_id) REFERENCES changes(change_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dependencies_dependency_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: -
--

ALTER TABLE ONLY dependencies
    ADD CONSTRAINT dependencies_dependency_id_fkey FOREIGN KEY (dependency_id) REFERENCES changes(change_id) ON UPDATE CASCADE;


--
-- Name: events_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_project_fkey FOREIGN KEY (project) REFERENCES projects(project) ON UPDATE CASCADE;


--
-- Name: tags_change_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_change_id_fkey FOREIGN KEY (change_id) REFERENCES changes(change_id) ON UPDATE CASCADE;


--
-- Name: tags_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_project_fkey FOREIGN KEY (project) REFERENCES projects(project) ON UPDATE CASCADE;


--
-- Name: 1; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA "1" FROM PUBLIC;
REVOKE ALL ON SCHEMA "1" FROM rs;
GRANT ALL ON SCHEMA "1" TO rs;
GRANT USAGE ON SCHEMA "1" TO anonymous;
GRANT USAGE ON SCHEMA "1" TO admin;
GRANT USAGE ON SCHEMA "1" TO web_user;


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM rs;
GRANT ALL ON SCHEMA public TO rs;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: rs; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA rs FROM PUBLIC;
REVOKE ALL ON SCHEMA rs FROM rs;
GRANT ALL ON SCHEMA rs TO rs;
GRANT ALL ON SCHEMA rs TO rede;
GRANT USAGE ON SCHEMA rs TO web_user;
GRANT USAGE ON SCHEMA rs TO admin;


SET search_path = rs, pg_catalog;

--
-- Name: afiliados; Type: ACL; Schema: rs; Owner: -
--

REVOKE ALL ON TABLE afiliados FROM PUBLIC;
REVOKE ALL ON TABLE afiliados FROM rs;
GRANT ALL ON TABLE afiliados TO rs;
GRANT SELECT ON TABLE afiliados TO web_user;
GRANT SELECT ON TABLE afiliados TO admin;


SET search_path = "1", pg_catalog;

--
-- Name: filiados; Type: ACL; Schema: 1; Owner: -
--

REVOKE ALL ON TABLE filiados FROM PUBLIC;
REVOKE ALL ON TABLE filiados FROM rs;
GRANT ALL ON TABLE filiados TO rs;
GRANT SELECT ON TABLE filiados TO admin;
GRANT SELECT ON TABLE filiados TO web_user;


SET search_path = rs, pg_catalog;

--
-- Name: regra_afiliados; Type: ACL; Schema: rs; Owner: -
--

REVOKE ALL ON TABLE regra_afiliados FROM PUBLIC;
REVOKE ALL ON TABLE regra_afiliados FROM rs;
GRANT ALL ON TABLE regra_afiliados TO rs;
GRANT SELECT ON TABLE regra_afiliados TO web_user;
GRANT SELECT ON TABLE regra_afiliados TO admin;


--
-- PostgreSQL database dump complete
--

