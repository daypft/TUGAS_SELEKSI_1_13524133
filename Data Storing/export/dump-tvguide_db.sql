--
-- PostgreSQL database dump
--

\restrict ZXAKb1xqV1lfguFi8eJYR1KDJu0swGklEWEXyEytbYX6LPUQ9nVEsy6eFB2Q399

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-07-23 15:02:07

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5117 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 252 (class 1255 OID 16637)
-- Name: prevent_schedule_overlap(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_schedule_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_start TIMESTAMP;
    new_end TIMESTAMP;
BEGIN
    new_start := NEW.broadcast_date + NEW.start_time;
    new_end := NEW.broadcast_date + NEW.end_time;

    IF NEW.end_time < NEW.start_time THEN
        new_end := new_end + INTERVAL '1 day';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM broadcast_schedules s
        WHERE s.channel_id = NEW.channel_id
          AND s.schedule_id IS DISTINCT FROM NEW.schedule_id
          AND new_start < s.broadcast_date + s.end_time
              + CASE WHEN s.end_time < s.start_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
          AND s.broadcast_date + s.start_time < new_end
    ) THEN
        RAISE EXCEPTION
            'schedule channel_id % overlaps an existing schedule', NEW.channel_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_schedule_overlap() OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 16631)
-- Name: validate_schedule_episode(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_schedule_episode() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.episode_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM episodes
           WHERE episode_id = NEW.episode_id
             AND program_id = NEW.program_id
       )
    THEN
        RAISE EXCEPTION 'episode_id % does not belong to program_id %',
            NEW.episode_id, NEW.program_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.validate_schedule_episode() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 226 (class 1259 OID 18082)
-- Name: broadcast_schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.broadcast_schedules (
    schedule_id integer NOT NULL,
    channel_id integer NOT NULL,
    program_id integer NOT NULL,
    episode_id integer,
    broadcast_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    is_live boolean DEFAULT false NOT NULL,
    is_new boolean DEFAULT false NOT NULL,
    CONSTRAINT chk_schedule_nonzero_duration CHECK ((end_time <> start_time))
);


ALTER TABLE public.broadcast_schedules OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 18063)
-- Name: episodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.episodes (
    episode_id integer NOT NULL,
    program_id integer NOT NULL,
    season_number integer NOT NULL,
    episode_number integer NOT NULL,
    episode_title character varying(500),
    episode_synopsis text,
    CONSTRAINT chk_episode_numbers_positive CHECK (((season_number > 0) AND (episode_number > 0)))
);


ALTER TABLE public.episodes OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 18036)
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    genre_name character varying(100) NOT NULL,
    CONSTRAINT chk_genre_name_not_blank CHECK ((btrim((genre_name)::text) <> ''::text))
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 18046)
-- Name: program_genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.program_genres (
    program_id integer NOT NULL,
    genre_id integer NOT NULL
);


ALTER TABLE public.program_genres OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 17998)
-- Name: program_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.program_types (
    program_type_id integer NOT NULL,
    type_name character varying(20) NOT NULL,
    CONSTRAINT chk_program_type_name CHECK (((type_name)::text = ANY ((ARRAY['movie'::character varying, 'sports'::character varying, 'family'::character varying, 'news'::character varying, 'other'::character varying])::text[])))
);


ALTER TABLE public.program_types OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 18008)
-- Name: tv_channels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tv_channels (
    channel_id integer NOT NULL,
    call_sign character varying(255) NOT NULL,
    CONSTRAINT chk_channel_call_sign_not_blank CHECK ((btrim((call_sign)::text) <> ''::text))
);


ALTER TABLE public.tv_channels OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 18018)
-- Name: tv_programs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tv_programs (
    program_id integer NOT NULL,
    program_type_id integer NOT NULL,
    title character varying(500) NOT NULL,
    description text,
    parental_rating character varying(30),
    CONSTRAINT chk_program_title_not_blank CHECK ((btrim((title)::text) <> ''::text))
);


ALTER TABLE public.tv_programs OWNER TO postgres;

--
-- TOC entry 5111 (class 0 OID 18082)
-- Dependencies: 226
-- Data for Name: broadcast_schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.broadcast_schedules (schedule_id, channel_id, program_id, episode_id, broadcast_date, start_time, end_time, is_live, is_new) FROM stdin;
1	1	1	\N	2026-07-23	13:00:00	16:00:00	f	t
2	2	2	\N	2026-07-23	13:00:00	16:00:00	f	t
3	3	3	\N	2026-07-23	11:00:00	17:00:00	f	f
4	4	4	\N	2026-07-23	13:13:00	14:00:00	f	t
5	4	5	\N	2026-07-23	14:00:00	14:30:00	f	t
6	4	5	\N	2026-07-23	14:30:00	15:00:00	f	t
7	4	5	\N	2026-07-23	15:00:00	15:30:00	f	t
8	5	6	\N	2026-07-23	13:00:00	14:00:00	f	f
9	5	7	\N	2026-07-23	14:00:00	15:00:00	f	f
10	5	8	\N	2026-07-23	15:00:00	16:00:00	f	f
11	6	3	\N	2026-07-23	11:00:00	17:00:00	f	f
12	7	3	\N	2026-07-23	11:00:00	17:00:00	f	f
13	8	9	1	2026-07-23	13:00:00	14:00:00	f	f
14	8	10	\N	2026-07-23	14:00:00	14:30:00	f	f
15	8	11	\N	2026-07-23	14:30:00	15:00:00	f	f
16	8	11	\N	2026-07-23	15:00:00	15:30:00	f	f
17	9	12	\N	2026-07-23	13:00:00	14:00:00	f	f
18	9	13	\N	2026-07-23	14:00:00	15:00:00	f	f
19	9	14	\N	2026-07-23	15:00:00	16:00:00	f	f
20	10	15	\N	2026-07-23	13:00:00	14:00:00	f	f
21	10	16	\N	2026-07-23	14:00:00	15:00:00	f	f
22	10	17	\N	2026-07-23	15:00:00	15:30:00	f	f
23	11	18	\N	2026-07-23	13:30:00	13:55:00	t	f
24	11	19	\N	2026-07-23	13:55:00	14:00:00	f	f
25	11	20	\N	2026-07-23	14:00:00	14:30:00	t	f
26	11	20	\N	2026-07-23	14:30:00	15:00:00	t	f
27	11	20	\N	2026-07-23	15:00:00	15:30:00	t	f
28	12	21	\N	2026-07-23	13:00:00	15:00:00	t	f
29	12	22	\N	2026-07-23	15:00:00	16:00:00	t	f
30	13	23	\N	2026-07-23	13:00:00	14:00:00	f	f
31	13	23	\N	2026-07-23	14:00:00	15:00:00	f	f
32	13	24	\N	2026-07-23	15:00:00	16:00:00	f	t
33	14	25	\N	2026-07-23	13:00:00	14:00:00	f	f
34	14	26	\N	2026-07-23	14:00:00	15:00:00	f	f
35	14	27	\N	2026-07-23	15:00:00	16:00:00	f	f
36	15	28	\N	2026-07-23	13:00:00	15:00:00	f	f
37	15	28	\N	2026-07-23	15:00:00	17:00:00	f	f
38	16	11	\N	2026-07-23	13:30:00	14:00:00	f	f
39	16	29	\N	2026-07-23	14:00:00	14:30:00	f	f
40	16	11	\N	2026-07-23	14:30:00	15:00:00	f	f
41	16	30	\N	2026-07-23	15:00:00	16:00:00	f	f
42	17	31	\N	2026-07-23	13:00:00	14:00:00	f	f
43	17	32	\N	2026-07-23	14:00:00	15:00:00	f	f
44	17	33	\N	2026-07-23	15:00:00	16:00:00	f	t
45	18	34	\N	2026-07-23	13:30:00	14:00:00	f	f
46	18	34	\N	2026-07-23	14:00:00	14:30:00	f	f
47	18	34	\N	2026-07-23	14:30:00	15:00:00	f	f
48	18	34	\N	2026-07-23	15:00:00	15:30:00	f	f
49	19	35	\N	2026-07-23	13:00:00	14:00:00	f	f
50	19	36	\N	2026-07-23	14:00:00	15:00:00	f	f
51	19	37	\N	2026-07-23	15:00:00	16:00:00	f	f
52	20	38	\N	2026-07-23	13:00:00	14:00:00	f	f
53	20	39	\N	2026-07-23	14:00:00	15:00:00	f	f
54	20	40	\N	2026-07-23	15:00:00	16:00:00	f	f
55	21	41	\N	2026-07-23	11:00:00	14:00:00	f	f
56	21	42	\N	2026-07-23	14:00:00	14:30:00	f	f
57	21	43	\N	2026-07-23	14:30:00	15:30:00	f	f
58	22	44	\N	2026-07-23	12:30:00	15:30:00	f	f
59	23	45	\N	2026-07-23	13:00:00	14:00:00	f	f
60	23	46	\N	2026-07-23	14:00:00	15:00:00	f	f
61	23	46	\N	2026-07-23	15:00:00	16:00:00	f	f
62	24	47	\N	2026-07-23	13:00:00	14:00:00	f	f
63	24	48	\N	2026-07-23	14:00:00	15:00:00	f	f
64	24	49	\N	2026-07-23	15:00:00	17:00:00	f	f
65	25	50	\N	2026-07-23	13:00:00	14:00:00	f	f
66	25	51	\N	2026-07-23	14:00:00	16:00:00	t	f
67	26	52	\N	2026-07-23	13:30:00	14:00:00	f	f
68	26	53	\N	2026-07-23	14:00:00	14:30:00	f	f
69	26	54	\N	2026-07-23	14:30:00	15:00:00	f	f
70	26	48	\N	2026-07-23	15:00:00	16:00:00	f	f
71	27	55	\N	2026-07-23	12:00:00	15:00:00	f	f
72	27	43	\N	2026-07-23	15:00:00	16:00:00	f	f
73	28	56	\N	2026-07-23	11:00:00	23:00:00	t	f
74	29	57	\N	2026-07-23	12:30:00	14:30:00	f	f
75	29	57	\N	2026-07-23	14:30:00	16:00:00	f	f
76	30	58	\N	2026-07-23	12:00:00	14:00:00	f	f
77	30	59	\N	2026-07-23	14:00:00	16:00:00	f	f
78	31	60	\N	2026-07-23	13:30:00	15:30:00	f	f
79	32	61	\N	2026-07-23	13:30:00	14:30:00	f	f
80	32	61	\N	2026-07-23	14:30:00	15:30:00	f	f
81	33	62	2	2026-07-23	13:00:00	14:00:00	f	f
82	33	62	3	2026-07-23	14:00:00	15:00:00	f	f
83	33	62	4	2026-07-23	15:00:00	16:00:00	f	f
84	34	63	\N	2026-07-23	13:30:00	14:00:00	f	f
85	34	64	\N	2026-07-23	14:00:00	14:30:00	f	f
86	34	64	\N	2026-07-23	14:30:00	15:00:00	f	f
87	34	65	\N	2026-07-23	15:00:00	16:00:00	f	f
88	35	66	\N	2026-07-23	13:00:00	14:00:00	f	f
89	35	67	\N	2026-07-23	14:00:00	15:00:00	f	f
90	35	67	\N	2026-07-23	15:00:00	16:00:00	f	f
91	36	68	\N	2026-07-23	13:00:00	15:00:00	f	f
92	36	68	\N	2026-07-23	15:00:00	17:00:00	f	f
93	37	69	\N	2026-07-23	13:00:00	14:00:00	f	f
94	37	69	\N	2026-07-23	14:00:00	15:00:00	f	f
95	37	69	\N	2026-07-23	15:00:00	16:00:00	f	f
96	38	70	\N	2026-07-23	13:30:00	14:00:00	f	f
97	38	71	\N	2026-07-23	14:00:00	14:30:00	f	f
98	38	72	\N	2026-07-23	14:30:00	15:00:00	f	f
99	38	73	\N	2026-07-23	15:00:00	15:30:00	f	f
100	39	74	\N	2026-07-23	08:00:00	14:30:00	f	f
101	39	75	\N	2026-07-23	14:30:00	18:00:00	f	f
102	40	76	\N	2026-07-23	11:00:00	16:00:00	f	f
103	41	77	\N	2026-07-23	13:04:00	13:34:00	f	f
104	41	77	\N	2026-07-23	13:34:00	14:05:00	f	f
105	41	77	\N	2026-07-23	14:05:00	14:34:00	f	f
106	41	77	\N	2026-07-23	14:34:00	15:02:00	f	f
107	41	11	\N	2026-07-23	15:02:00	15:32:00	f	f
108	42	78	5	2026-07-23	13:00:00	14:00:00	f	f
109	42	78	6	2026-07-23	14:00:00	15:00:00	f	f
110	42	79	7	2026-07-23	15:00:00	16:00:00	f	f
111	43	80	8	2026-07-23	12:30:00	13:40:00	f	f
112	43	80	9	2026-07-23	13:43:00	14:39:00	f	f
113	43	80	9	2026-07-23	14:39:00	15:40:00	f	f
114	44	81	10	2026-07-23	13:00:00	15:00:00	f	f
115	44	82	11	2026-07-23	15:00:00	16:00:00	f	f
116	45	83	12	2026-07-23	13:00:00	14:00:00	f	f
117	45	83	13	2026-07-23	14:00:00	15:00:00	f	f
118	45	83	14	2026-07-23	15:00:00	16:00:00	f	f
119	46	84	15	2026-07-23	13:30:00	14:00:00	f	f
120	46	84	16	2026-07-23	14:00:00	14:30:00	f	f
121	46	84	17	2026-07-23	14:30:00	15:00:00	f	f
122	46	85	18	2026-07-23	15:00:00	15:30:00	f	f
123	47	86	19	2026-07-23	13:12:00	13:48:00	f	f
124	47	86	20	2026-07-23	13:48:00	14:24:00	f	f
125	47	86	21	2026-07-23	14:24:00	15:00:00	f	f
126	47	87	\N	2026-07-23	15:00:00	16:00:00	f	f
127	48	88	22	2026-07-23	13:30:00	14:00:00	f	f
128	48	89	23	2026-07-23	14:00:00	14:10:00	f	f
129	48	89	24	2026-07-23	14:10:00	14:20:00	f	f
130	48	89	\N	2026-07-23	14:20:00	14:30:00	f	f
131	48	89	25	2026-07-23	14:30:00	14:40:00	f	f
132	48	89	26	2026-07-23	14:40:00	14:50:00	f	f
133	48	89	27	2026-07-23	14:50:00	15:00:00	f	f
134	48	90	28	2026-07-23	15:00:00	15:10:00	f	f
135	48	90	29	2026-07-23	15:10:00	15:20:00	f	f
136	49	91	\N	2026-07-23	13:30:00	14:30:00	f	f
137	49	92	30	2026-07-23	14:30:00	15:00:00	f	t
138	49	93	31	2026-07-23	15:00:00	16:00:00	f	f
139	50	94	32	2026-07-23	13:32:00	14:01:00	f	f
140	50	94	33	2026-07-23	14:01:00	14:30:00	f	f
141	50	95	34	2026-07-23	14:30:00	15:00:00	f	f
142	50	95	35	2026-07-23	15:00:00	15:30:00	f	f
143	51	96	36	2026-07-23	13:30:00	14:00:00	f	f
144	51	97	\N	2026-07-23	14:00:00	15:00:00	f	f
145	51	97	\N	2026-07-23	15:00:00	16:00:00	f	f
146	52	98	\N	2026-07-23	13:30:00	14:00:00	f	f
147	52	98	\N	2026-07-23	14:00:00	14:30:00	f	f
148	52	98	\N	2026-07-23	14:30:00	15:00:00	f	f
149	52	98	\N	2026-07-23	15:00:00	15:30:00	f	f
150	53	99	37	2026-07-23	13:00:00	14:00:00	f	f
151	53	99	38	2026-07-23	14:00:00	15:00:00	f	f
152	53	11	\N	2026-07-23	15:00:00	15:30:00	f	f
153	54	100	39	2026-07-23	13:00:00	14:00:00	f	f
154	54	100	40	2026-07-23	14:00:00	15:00:00	f	f
155	54	100	41	2026-07-23	15:00:00	16:00:00	f	f
156	55	101	42	2026-07-23	13:00:00	14:00:00	f	f
157	55	101	43	2026-07-23	14:00:00	15:00:00	f	f
158	55	102	44	2026-07-23	15:00:00	15:30:00	f	f
159	56	103	45	2026-07-23	13:30:00	15:00:00	f	f
160	56	104	\N	2026-07-23	15:00:00	16:00:00	f	f
161	57	105	\N	2026-07-23	13:00:00	14:00:00	f	f
162	57	106	\N	2026-07-23	14:00:00	15:00:00	f	f
163	57	107	\N	2026-07-23	15:00:00	15:30:00	f	f
164	58	108	46	2026-07-23	13:00:00	15:00:00	f	f
165	58	108	47	2026-07-23	15:00:00	17:00:00	f	f
166	59	109	48	2026-07-23	13:30:00	14:00:00	f	f
167	59	110	49	2026-07-23	14:00:00	14:30:00	f	f
168	59	110	50	2026-07-23	14:30:00	15:00:00	f	f
169	59	111	51	2026-07-23	15:00:00	15:30:00	f	f
170	60	112	\N	2026-07-23	13:10:00	13:35:00	f	f
171	60	113	52	2026-07-23	13:35:00	14:00:00	f	f
172	60	114	53	2026-07-23	14:00:00	14:25:00	f	f
173	60	115	\N	2026-07-23	14:25:00	14:50:00	f	f
174	60	115	\N	2026-07-23	14:50:00	15:15:00	f	f
175	61	116	54	2026-07-23	13:30:00	14:00:00	f	f
176	61	117	55	2026-07-23	14:00:00	14:30:00	f	f
177	61	117	56	2026-07-23	14:30:00	15:00:00	f	f
178	61	118	57	2026-07-23	15:00:00	15:30:00	f	f
179	62	119	\N	2026-07-23	13:00:00	15:00:00	f	f
180	62	120	\N	2026-07-23	15:00:00	17:00:00	f	f
181	63	121	58	2026-07-23	13:00:00	14:00:00	f	f
182	63	121	59	2026-07-23	14:00:00	15:00:00	f	f
183	63	121	60	2026-07-23	15:00:00	16:00:00	f	f
184	64	122	\N	2026-07-23	13:30:00	14:00:00	f	f
185	64	123	61	2026-07-23	14:00:00	15:00:00	f	f
186	64	11	\N	2026-07-23	15:00:00	15:30:00	f	f
187	65	124	\N	2026-07-23	13:00:00	16:00:00	f	f
188	66	125	62	2026-07-23	13:30:00	14:00:00	f	f
189	66	125	63	2026-07-23	14:00:00	14:30:00	f	f
190	66	125	64	2026-07-23	14:30:00	15:00:00	f	f
191	66	11	\N	2026-07-23	15:00:00	15:30:00	f	f
192	67	126	\N	2026-07-23	12:10:00	14:50:00	f	f
193	67	127	\N	2026-07-23	14:50:00	17:00:00	f	f
194	68	128	65	2026-07-23	13:00:00	14:01:00	f	f
195	68	128	66	2026-07-23	14:01:00	15:00:00	f	f
196	68	128	67	2026-07-23	15:00:00	16:00:00	f	f
197	69	129	\N	2026-07-23	13:00:00	15:00:00	f	f
198	69	130	\N	2026-07-23	15:00:00	17:00:00	f	f
199	70	131	68	2026-07-23	13:30:00	14:00:00	f	f
200	70	132	69	2026-07-23	14:00:00	14:30:00	f	f
201	70	132	70	2026-07-23	14:30:00	15:00:00	f	f
202	70	133	\N	2026-07-23	15:00:00	15:30:00	f	f
203	71	134	71	2026-07-23	13:00:00	14:00:00	f	f
204	71	134	72	2026-07-23	14:00:00	15:00:00	f	f
205	71	134	73	2026-07-23	15:00:00	16:00:00	f	f
206	72	135	\N	2026-07-23	13:00:00	14:00:00	f	f
207	72	136	74	2026-07-23	14:00:00	15:00:00	f	f
208	72	136	75	2026-07-23	15:00:00	16:00:00	f	f
209	73	137	76	2026-07-23	13:00:00	14:00:00	f	f
210	73	137	77	2026-07-23	14:00:00	15:00:00	f	f
211	73	137	78	2026-07-23	15:00:00	16:00:00	f	f
212	74	138	\N	2026-07-23	13:31:00	14:00:00	f	f
213	74	139	\N	2026-07-23	14:00:00	15:00:00	f	f
214	74	140	79	2026-07-23	15:00:00	16:00:00	f	f
215	75	141	80	2026-07-23	13:33:00	14:32:00	f	f
216	75	142	81	2026-07-23	14:32:00	15:01:00	f	f
217	75	11	\N	2026-07-23	15:01:00	15:30:00	f	f
218	76	143	82	2026-07-23	13:30:00	14:00:00	f	f
219	76	143	83	2026-07-23	14:00:00	14:30:00	f	f
220	76	143	84	2026-07-23	14:30:00	15:00:00	f	f
221	76	143	85	2026-07-23	15:00:00	15:30:00	f	f
222	77	144	86	2026-07-23	13:00:00	14:00:00	f	f
223	77	145	87	2026-07-23	14:00:00	15:00:00	f	f
224	77	144	88	2026-07-23	15:00:00	16:00:00	f	f
225	78	146	89	2026-07-23	13:04:00	14:04:00	f	f
226	78	146	90	2026-07-23	14:04:00	15:02:00	f	f
227	78	11	\N	2026-07-23	15:02:00	15:32:00	f	f
228	79	147	\N	2026-07-23	13:01:00	15:02:00	f	f
229	79	148	\N	2026-07-23	15:02:00	15:32:00	f	f
230	80	149	91	2026-07-23	13:00:00	14:00:00	f	f
231	80	149	92	2026-07-23	14:00:00	15:00:00	f	f
232	80	149	93	2026-07-23	15:00:00	16:00:00	f	f
233	81	150	94	2026-07-23	13:00:00	14:00:00	f	f
234	81	150	95	2026-07-23	14:00:00	15:00:00	f	f
235	81	151	96	2026-07-23	15:00:00	16:00:00	f	f
236	82	152	97	2026-07-23	13:30:00	14:00:00	f	f
237	82	152	97	2026-07-23	14:00:00	14:30:00	f	f
238	82	152	98	2026-07-23	14:30:00	15:00:00	f	f
239	82	152	99	2026-07-23	15:00:00	15:30:00	f	f
240	83	153	100	2026-07-23	13:30:00	14:00:00	f	f
241	83	154	101	2026-07-23	14:00:00	14:30:00	f	f
242	83	154	102	2026-07-23	14:30:00	15:00:00	f	f
243	83	154	103	2026-07-23	15:00:00	15:30:00	f	f
244	84	155	104	2026-07-23	13:00:00	14:00:00	f	f
245	84	155	105	2026-07-23	14:00:00	15:00:00	f	f
246	84	155	106	2026-07-23	15:00:00	16:00:00	f	f
247	85	156	107	2026-07-23	12:38:00	13:38:00	f	f
248	85	157	108	2026-07-23	13:38:00	14:00:00	f	f
249	85	11	\N	2026-07-23	14:00:00	14:30:00	f	f
250	85	11	\N	2026-07-23	14:30:00	15:00:00	f	f
251	85	29	\N	2026-07-23	15:00:00	15:30:00	f	f
252	86	158	\N	2026-07-23	13:30:00	14:00:00	f	f
253	86	158	109	2026-07-23	14:00:00	14:30:00	f	f
254	86	158	110	2026-07-23	14:30:00	15:00:00	f	f
255	86	158	111	2026-07-23	15:00:00	15:30:00	f	f
256	87	159	112	2026-07-23	13:15:00	13:39:00	f	f
257	87	160	113	2026-07-23	13:39:00	14:04:00	f	f
258	87	160	114	2026-07-23	14:04:00	14:28:00	f	f
259	87	161	115	2026-07-23	14:28:00	14:52:00	f	f
260	87	161	116	2026-07-23	14:52:00	15:17:00	f	f
261	87	160	117	2026-07-23	15:17:00	15:41:00	f	f
262	88	162	118	2026-07-23	13:25:00	13:50:00	f	f
263	88	163	119	2026-07-23	13:50:00	14:15:00	f	f
264	88	163	120	2026-07-23	14:15:00	14:30:00	f	f
265	88	163	120	2026-07-23	14:30:00	14:55:00	f	f
266	88	163	121	2026-07-23	14:55:00	15:20:00	f	f
267	89	164	122	2026-07-23	13:30:00	14:00:00	f	f
268	89	165	\N	2026-07-23	14:00:00	14:30:00	f	f
269	89	166	\N	2026-07-23	14:30:00	15:00:00	f	f
270	89	11	\N	2026-07-23	15:00:00	15:30:00	f	f
271	90	167	123	2026-07-23	13:30:00	14:00:00	f	f
272	90	167	124	2026-07-23	14:00:00	14:30:00	f	f
273	90	167	125	2026-07-23	14:30:00	15:00:00	f	f
274	90	168	126	2026-07-23	15:00:00	16:00:00	f	f
275	91	169	\N	2026-07-23	13:00:00	14:00:00	f	f
276	91	23	\N	2026-07-23	14:00:00	15:00:00	f	f
277	91	23	\N	2026-07-23	15:00:00	16:00:00	f	f
278	92	170	\N	2026-07-23	13:00:00	16:00:00	f	f
279	93	171	127	2026-07-23	13:00:00	14:00:00	f	f
280	93	171	128	2026-07-23	14:00:00	15:00:00	f	f
281	93	171	129	2026-07-23	15:00:00	16:00:00	f	f
282	94	172	130	2026-07-23	11:00:00	14:00:00	f	f
283	94	166	\N	2026-07-23	14:00:00	14:30:00	f	f
284	94	11	\N	2026-07-23	14:30:00	15:00:00	f	f
285	94	11	\N	2026-07-23	15:00:00	15:30:00	f	f
286	95	173	131	2026-07-23	13:00:00	14:00:00	f	f
287	95	173	\N	2026-07-23	14:00:00	15:00:00	f	f
288	95	174	\N	2026-07-23	15:00:00	16:00:00	f	f
289	96	175	\N	2026-07-23	13:00:00	14:00:00	f	f
290	96	175	132	2026-07-23	14:00:00	15:00:00	f	f
291	96	175	133	2026-07-23	15:00:00	16:00:00	f	f
292	97	176	134	2026-07-23	13:00:00	14:00:00	f	f
293	97	176	135	2026-07-23	14:00:00	15:00:00	f	f
294	97	177	136	2026-07-23	15:00:00	15:30:00	f	f
295	98	178	\N	2026-07-23	12:00:00	14:00:00	f	f
296	98	179	137	2026-07-23	14:00:00	15:00:00	f	f
297	98	179	138	2026-07-23	15:00:00	16:00:00	f	f
298	99	180	139	2026-07-23	13:30:00	14:00:00	f	f
299	99	180	140	2026-07-23	14:00:00	14:30:00	f	f
300	99	180	141	2026-07-23	14:30:00	15:00:00	f	f
301	99	180	142	2026-07-23	15:00:00	15:30:00	f	f
302	100	181	\N	2026-07-23	13:00:00	16:15:00	f	f
303	101	182	143	2026-07-23	13:24:00	13:48:00	f	f
304	101	183	144	2026-07-23	13:48:00	14:12:00	f	f
305	101	183	144	2026-07-23	14:12:00	14:36:00	f	f
306	101	183	144	2026-07-23	14:36:00	15:00:00	f	f
307	101	183	145	2026-07-23	15:00:00	15:24:00	f	f
308	102	184	146	2026-07-23	13:00:00	14:00:00	f	f
309	102	184	146	2026-07-23	14:00:00	15:00:00	f	f
310	102	185	147	2026-07-23	15:00:00	16:00:00	f	f
311	103	186	148	2026-07-23	13:00:00	14:00:00	f	f
312	103	186	149	2026-07-23	14:00:00	15:00:00	f	f
313	103	186	150	2026-07-23	15:00:00	16:00:00	f	f
314	104	187	151	2026-07-23	13:00:00	14:00:00	f	f
315	104	187	152	2026-07-23	14:00:00	15:00:00	f	f
316	104	187	153	2026-07-23	15:00:00	16:00:00	f	f
317	105	188	154	2026-07-23	13:30:00	14:00:00	f	f
318	105	188	154	2026-07-23	14:00:00	14:30:00	f	f
319	105	188	155	2026-07-23	14:30:00	15:00:00	f	f
320	105	10	\N	2026-07-23	15:00:00	15:30:00	f	f
321	106	189	156	2026-07-23	13:30:00	14:00:00	f	f
322	106	189	157	2026-07-23	14:00:00	14:30:00	f	f
323	106	189	158	2026-07-23	14:30:00	15:00:00	f	f
324	106	96	159	2026-07-23	15:00:00	15:30:00	f	f
325	107	190	160	2026-07-23	13:30:00	14:00:00	f	f
326	107	23	\N	2026-07-23	14:00:00	15:00:00	f	f
327	107	23	\N	2026-07-23	15:00:00	16:00:00	f	f
328	108	191	161	2026-07-23	13:30:00	14:00:00	f	f
329	108	191	162	2026-07-23	14:00:00	14:30:00	f	f
330	108	191	163	2026-07-23	14:30:00	15:00:00	f	f
331	108	191	164	2026-07-23	15:00:00	15:30:00	f	f
332	109	192	\N	2026-07-23	13:00:00	14:00:00	f	f
333	109	192	\N	2026-07-23	14:00:00	15:00:00	f	f
334	109	192	\N	2026-07-23	15:00:00	16:00:00	f	f
335	110	193	165	2026-07-23	13:00:00	14:00:00	f	f
336	110	193	166	2026-07-23	14:00:00	15:00:00	f	f
337	110	194	167	2026-07-23	15:00:00	16:00:00	f	f
338	111	195	168	2026-07-23	13:00:00	14:00:00	f	f
339	111	195	169	2026-07-23	14:00:00	15:00:00	f	f
340	111	196	170	2026-07-23	15:00:00	16:00:00	f	f
341	112	197	171	2026-07-23	12:30:00	13:37:00	f	f
342	112	198	172	2026-07-23	13:37:00	14:15:00	f	f
343	112	199	\N	2026-07-23	14:15:00	15:55:00	f	f
344	113	200	\N	2026-07-23	12:34:00	14:34:00	f	f
345	113	201	\N	2026-07-23	14:34:00	15:42:00	f	f
346	114	202	\N	2026-07-23	13:20:00	15:37:00	f	f
347	115	203	173	2026-07-23	12:46:00	13:49:00	f	f
348	115	203	174	2026-07-23	13:49:00	14:44:00	f	f
349	115	203	175	2026-07-23	14:44:00	15:56:00	f	f
350	116	204	\N	2026-07-23	11:45:00	14:13:00	f	f
351	116	205	\N	2026-07-23	14:14:00	16:03:00	f	f
352	117	206	\N	2026-07-23	12:11:00	13:41:00	f	f
353	117	207	\N	2026-07-23	13:41:00	15:07:00	f	f
354	117	208	\N	2026-07-23	15:07:00	17:06:00	f	f
355	118	209	\N	2026-07-23	12:37:00	14:29:00	f	f
356	118	210	\N	2026-07-23	14:29:00	15:57:00	f	f
357	119	211	\N	2026-07-23	12:47:00	14:24:00	f	f
358	119	212	\N	2026-07-23	14:24:00	15:57:00	f	f
359	120	213	\N	2026-07-23	12:16:00	14:17:00	f	f
360	120	214	\N	2026-07-23	14:17:00	15:49:00	f	f
361	121	215	\N	2026-07-23	12:05:00	13:50:00	f	f
362	121	216	\N	2026-07-23	13:50:00	15:45:00	f	f
363	122	217	\N	2026-07-23	13:00:00	15:00:00	f	f
364	122	218	\N	2026-07-23	15:00:00	17:00:00	f	f
365	123	219	\N	2026-07-23	13:15:00	14:50:00	f	f
366	123	220	\N	2026-07-23	14:50:00	16:05:00	f	f
367	124	221	\N	2026-07-23	13:20:00	15:10:00	f	f
368	124	222	\N	2026-07-23	15:10:00	16:35:00	f	f
369	125	223	\N	2026-07-23	12:00:00	13:45:00	f	f
370	125	224	\N	2026-07-23	13:45:00	15:10:00	f	f
371	125	225	\N	2026-07-23	15:10:00	17:00:00	f	f
372	126	226	\N	2026-07-23	11:35:00	13:35:00	f	f
373	126	227	\N	2026-07-23	13:35:00	15:15:00	f	f
374	126	228	\N	2026-07-23	15:15:00	17:00:00	f	f
375	127	229	\N	2026-07-23	12:00:00	13:50:00	f	f
376	127	230	\N	2026-07-23	13:50:00	15:15:00	f	f
377	127	231	\N	2026-07-23	15:15:00	17:05:00	f	f
378	128	232	\N	2026-07-23	12:05:00	13:40:00	f	f
379	128	233	\N	2026-07-23	13:40:00	15:35:00	f	f
380	129	234	\N	2026-07-23	12:30:00	14:30:00	f	f
381	129	235	\N	2026-07-23	14:30:00	16:15:00	f	f
382	130	236	\N	2026-07-23	13:00:00	15:00:00	f	f
383	130	237	\N	2026-07-23	15:00:00	17:15:00	f	f
384	131	238	\N	2026-07-23	13:25:00	15:00:00	f	f
385	131	239	\N	2026-07-23	15:00:00	16:30:00	f	f
386	132	240	\N	2026-07-23	11:31:00	13:34:00	f	f
387	132	241	\N	2026-07-23	13:34:00	15:22:00	f	f
388	132	242	\N	2026-07-23	15:22:00	17:36:00	f	f
389	133	243	\N	2026-07-23	12:20:00	14:07:00	f	f
390	133	244	\N	2026-07-23	14:07:00	16:00:00	f	f
391	134	245	\N	2026-07-23	12:14:00	13:55:00	f	f
392	134	246	\N	2026-07-23	13:55:00	15:22:00	f	f
393	134	247	\N	2026-07-23	15:22:00	17:31:00	f	f
394	135	248	\N	2026-07-23	13:32:00	15:26:00	f	f
395	135	249	\N	2026-07-23	15:26:00	16:48:00	f	f
396	136	250	\N	2026-07-23	13:23:00	15:44:00	f	f
397	137	251	\N	2026-07-23	13:33:00	15:01:00	f	f
398	137	252	\N	2026-07-23	15:01:00	16:38:00	f	f
399	138	253	\N	2026-07-23	13:31:00	15:06:00	f	f
400	138	254	\N	2026-07-23	15:06:00	16:26:00	f	f
401	139	255	\N	2026-07-23	12:02:00	13:36:00	f	f
402	139	256	\N	2026-07-23	13:36:00	15:06:00	f	f
403	139	257	\N	2026-07-23	15:06:00	16:57:00	f	f
404	140	258	\N	2026-07-23	13:15:00	14:24:00	f	f
405	140	259	\N	2026-07-23	14:24:00	15:53:00	f	f
406	141	260	\N	2026-07-23	12:08:00	13:51:00	f	f
407	141	261	\N	2026-07-23	13:51:00	15:16:00	f	f
408	141	262	\N	2026-07-23	15:16:00	17:04:00	f	f
409	142	263	\N	2026-07-23	13:01:00	14:43:00	f	f
410	142	264	\N	2026-07-23	14:43:00	16:42:00	f	f
411	143	265	\N	2026-07-23	12:04:00	13:58:00	f	f
412	143	266	\N	2026-07-23	13:58:00	15:45:00	f	f
413	144	267	\N	2026-07-23	13:21:00	14:42:00	f	f
414	144	268	\N	2026-07-23	14:42:00	15:51:00	f	f
415	145	269	\N	2026-07-23	13:05:00	13:55:00	f	f
416	145	270	\N	2026-07-23	13:55:00	15:25:00	f	f
417	145	271	\N	2026-07-23	15:25:00	17:00:00	f	f
418	146	272	\N	2026-07-23	13:25:00	15:35:00	f	f
419	147	273	\N	2026-07-23	12:20:00	14:05:00	f	f
420	147	274	\N	2026-07-23	14:05:00	16:00:00	f	f
421	148	275	\N	2026-07-23	13:25:00	15:05:00	f	f
422	148	276	\N	2026-07-23	15:05:00	17:00:00	f	f
\.


--
-- TOC entry 5110 (class 0 OID 18063)
-- Dependencies: 225
-- Data for Name: episodes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.episodes (episode_id, program_id, season_number, episode_number, episode_title, episode_synopsis) FROM stdin;
1	9	22	2	Ballad of Dwight and Irena	Rollins and Kat tend to a dangerous domestic violence call; Fin provides his deposition in the lawsuit against him.
2	62	1	9	McLaren P1	\N
3	62	1	7	Hilux Australia	\N
4	62	1	5	Ford Xr8 Australia	\N
5	78	2	1	Fighting Fox: Road to Hell	A detailed examination of the paratroopers of Fighting Fox Company, who fought and died in World War II battles from Normandy to Hitler's Eagle's Nest, demonstrating both dogged determination...
6	78	2	3	The Magnificent Bastards of Dai Do	The story of the men of Echo Company, charged with facing down an overwhelming North Vietnamese Army in Dai Do, in order to rescue their fellow Marines.
7	79	1	2	Escape From Moscow	Oleg Gordievsky, colonel in the KGB, the Soviet's Committee for State Security, spends ten years spying for Britain's Secret Intelligence Service when he discovers that the Soviets are...
8	80	1	1	Old Acquaintances	Once Maggie finds Negan, they travel to Manhattan; Negan is followed by a marshal named Armstrong; a quiet girl named Ginny.
9	80	1	2	Who's There?	Negan and Maggie meet native New Yorkers; Armstrong confronts a trauma; Ginny must try to adapt to change.
10	81	14	9	Legends and Rookies	Legendary survivalists Max and Rylie join two novice fans in the South African bush, where they must survive for three weeks among spitting cobras, aggressive warthogs, rhinos and...
11	82	6	10	Paranormal Cat- tivity	After a desperate woman posts a video looking for a home for her problematic cat Jimmy Slap, Jackson is called in to offer her the help she needs; Harold the cat wants to kill fellow feline...
12	83	6	18	Lauren	Prentiss feels that she is ready to finally confront her nemesis, Ian Doyle, once and for all; the BAU team calls upon their beloved former team member in JJ to help them find Prentiss and...
13	83	6	19	With Friends Like These...	When a gang of suspected murderers start targeting a new victim per night, the BAU team travels to Portland to stop them before they can strike again; Hotch is on the hunt to find another...
14	83	6	20	Hanley Waters	As the team struggles to cope with the loss of Prentiss, a woman in a psychotic break goes on a killing rampage and seemingly behaves completely on emotion, as her victims are killed at random...
15	84	2	11	Too Much Soul Food	Jamie and the family attempt to have a nice Thanksgiving dinner but when an unexpected accident befalls the head of the household the entire day is ruined with they are forced to go to the...
16	84	2	12	Super Face-Off	Jamie brags about being named the employee of the month at the hotel; a Los Angeles jewel thief is on the loose within the city, and Jamie is mistaken by authorities for the real culprit and...
17	84	2	13	Soul Mate to Cellmate	Jamie begins dating a woman he meets at the hotel in order to make Fancy jealous, but he later discovers that the woman is married to a man in prison, and he expects to return home to his wife...
18	85	10	3	All Lumped Together	Ella faces a frightening health situation after her annual mammogram reveals she has a lump in her breast; Malik's scholarship hangs in the balance when he faces the difficult choice between...
19	86	4	16	Golden Oldie	Mr. Brown's girlfriend is furious to learn Anastasia is competing in the same pageant as her; Leah is shocked when Jeremy buys her a broom for a birthday gift.
20	86	4	17	Big Thanks Little Thanks	Sandra's stint preparing Thanksgiving turkey leads to a lot of hungry residents; Anastasia struggles with the passing of an old friend.
21	86	4	18	Super Senior	Anastasia's plans to return to college face the reality of changing times; a rival facility challenges the Pleasant Days team to a charity walk.
22	88	1	10	Lucky Girl	A magician whose intimidating powers originate from within a set of mystical charms faces off against Ben in a battle that becomes increasingly ominous for the villain when his foe uses the...
23	89	2	2	Down and Outing	Tom and Jerry try to do each other in during a fishing trip.
24	89	3	3	It's Greek to Me-ow	Tom chases Jerry around during the times of Ancient Greece.
25	89	3	5	Landing Stripling	Classic "cat and mouse" tales pit a hungry and high-spirited cat against a loveable and lively mouse as they romp and run through adventures that are full of mischief and mayhem, as well as...
26	89	3	6	Calypso Cat	Tom falls in love with a cat, but she loses interest in him when they reach an island.
27	89	2	8	Dicky Moe	Tom and Jerry are along for a ride on a ship as the captain is obsessed with killing a white whale.
28	90	1	116	Too Weak to Work	Bluto checks himself into the hospital to fake exhaustion so that he can get some rest and enjoy some peace and quiet, and when Popeye discovers what Bluto is up to, he plays a trick on his...
29	90	11	5	Ration Fer the Duration	Popeye lectures his nephews on being productive with their time as he plants a victory garden, and when Popeye then falls asleep, he has a dream about climbing a giant beanstalk, which leads...
30	92	23	121	Kristen Doute & Ariana Biermann	TV personalities Ariana Biermann and Kristen Doute.
31	93	7	174	Season 7 Episode 174	Grammy Award-winning artist Kelly Clarkson interviews some of the biggest stars in the entertainment industry, spotlights individuals who have made a difference in their communities, and...
32	94	19	7	Beyond the Alcove or: How I Learned to Stop Worrying and Love Klaus	Francine promises to take Klaus down because she is jealous of his improvements.
33	94	19	8	A Song of Knives and Fire	Stan and Francine assess their relationship and add some much-needed fire.
34	95	9	9	Salute Your Morts	Morty and Summer go to camp, broh. Beth and Jerry home alone, broh.
35	95	3	3	Pickle Rick	Rick's daughter named Beth decides to take her two children known as Summer and Morty Smith to a family therapy session, but her plans goes awry when her father Rick manages to turn himself...
36	96	2	10	Love, Rose	Blanche and Dorothy create a fictional admirer to answer Rose's personal ad, but the meddlesome roommates are left scrambling when she decides to invite who she believes to be her imaginary...
37	99	2	3	'Hot' Chocolate	Valerie Bertinelli and Duff Goldman ask the remaining bakers to incorporate chilies, peppers, and cayenne into the chocolate items the bakers prepared causing the kids to be able to balance...
38	99	2	4	Macaron Stackaron	The seven remaining kid bakers are challenged with preparing what is being called "the new cupcake," the French macaron, said to be extremely demanding, and producing three dozen colorful...
39	100	1	5	The Night Shift	A college student disappears from his graveyard shift at a gas station; new forensic technology and the discovery of an illegal drug ring in a squeaky-clean town helps police solve the case...
40	100	2	8	Ice Cold in Denver	Radio intern Helene Pruszynski is found brutalized in a snowy field in 1980; the case goes cold for 37 years until investigators use a public genealogy website that leads them across the...
41	100	2	15	Friday Night Ghosts	After five people are found murdered in an oil field in 1983, the authorities name a well-connected local man as their main suspect, but new evidence reveals that the true killers had been...
42	101	3	5	Doctors, Divas and 2 Worthless Nuts	The competition pits potential Pitmasters against one another in Salisbury, Md., where Purdue Chicken got its humble start, which is why the competitors are tasked with creating various...
43	101	3	6	The Grand Porkin' Finale	Finalists come together for one last competitive showdown, where their barbecue skills are put to the ultimate test and only one worthy challenger will be able to walk away with the...
44	102	27	2	Cozying Up to a House on the Canal in Jamaica Beach	A family of five who enjoys spending time in Galveston, Texas, wants to find peace and quiet in the nearby city of Jamaica Beach, Texas, so they're on the hunt for a turnkey abode that boasts...
45	103	8	2	Searching for America's Lost Flight	Host Josh Gates investigates one of the most mysterious airline disasters in the history of the United States as he attempts to uncover why Northwest Flight 2501 seemingly disappeared out of...
46	108	12	7	Charles' Journey	After quitting his drug addiction, a man instead became addicted to food and soon found himself unable to stop even as he continues to put on weight.
47	108	8	1	John & Lonnie's Story	Despite being on opposite ends of the spectrum and estranged for many years, brothers Lonnie and John find common ground when they make it their goal to live a healthier lifestyle and...
48	109	3	2	Boss Life; Papaganda	Gloria's café has a perfect rating, and she works hard to keep it that way until someone gives her a B rating; Bill drags his family along on a blackberry picking adventure and enforces a...
49	110	3	3	Little Buddy; Zen Garden	A wild child needs Cricket's guidance, so he steps up as a mentor and Tilly develops a loyal underground following; Nancy works to prove she can be useful on the farm while Bill tries and...
50	110	3	4	No Service; Takened	A convenience store's "No Shoes, No Service" policy stops Cricket in his barefooted tracks and forces him to borrow Tilly's shoes; Bill struggles to keep a secret after he learns that Remy is...
51	111	1	15	Mall Leader; Ghost Wolf's Art	Kiff discovers the burdens of leadership while leading a group to the mall for free pretzels; Kiff and Barry hope to learn about the mysterious Ghost Wolf.
52	113	5	13	Chef Goofy on the Go!	Mickey and the rest of the friends assist Goofy with completing his food deliveries for his lunch truck, which he calls "Chef Goofy on the Go."
53	114	5	7	Mickey's Mousekeball	When Professor Von Drake introduces Mickey and his friends to a new innovative sport, the ball they're using gets away from them, so they are forced to change their playing field to the...
54	116	3	1	The Hyper-potamus Pizza-Party-torium	Lacking certain members, the team tries to prevent Noodle Burger Boy from achieving his goals while he is aided by his new family.
55	117	2	17	What Ever Happened to Donald Duck?!	Donald and Penumbra are forced to figure out how to escape from Moon Prison before they can warn planet Earth about an impending invasion; Dewey and Webby happen upon an evil conspiracy that...
56	117	2	19	A Nightmare on Killmotor Hill	The children are drawn into a magical world that is comprised of their most exotic dreams, but the situation takes a dark turn when Lena's worst nightmare is actualized, where Magica De Spell...
57	118	1	16	Family Fishing Trip; Bizarre Bazaar	Sprig hopes to spend more time with Hop Pop while the family is out on a fishing trip, but one of Hop Pop's friend keeps getting in the way; Anne loses her music box while explores the strange...
58	121	41	4	Food Family Takeover	Three restaurant crews featuring family and longtime employees compete.
59	121	38	4	Masters of Cheese	Four cheese-loving chefs face off in two Muenster-sized challenges in which Guy Fieri rolls a cheese die to determine who many types of cheese they must use in their dishes on their way to...
60	121	39	11	Super Spicy Games	our chefs obsessed with spice bring the heat with a hometown dish, and then Guy Fieri challenges them to create an upscale spicy dinner featuring ingredients chosen from a pyramid of fire for...
61	123	60	145	Season 60 Episode 145	Host and Reverend Pat Robertson joins a panel of guests for a discussion of religious commentary on news events, featured stories, contemporary music, interviews, testamonies, politics, the...
62	125	12	11	Trans-Fascism	The Arlen City Council's ban on foods containing trans-fats leads Hank to get involved in a dirty battle between two rival lunch trucks that are trying to traffic their tasty, unhealthy fare...
63	125	12	12	Three Men and a Bastard	Bill starts dating a single mother; but when Dale suspects that the woman's oldest child may in fact be his own offspring, he recruits John Redcorn to ruin the romance by seducing her, which...
64	125	12	13	Accidental Terrorist	Hank is distraught to discover that his trusted car salesman has been swindling him for years, but when he tries to take action to expose the fraud he ends up getting blamed for an act of...
65	128	1	4	Flushed in West Milford	Michelle and Jon work on a monstrous house as they venture outside of their comfort zone, and they have a hard time renovating the home's three bathrooms while also contending with supply...
66	128	1	3	Hasbrouck Heights Duplex Delights	Jon and Michelle worry that a multi-family home in Hasbrouck Heights may be their first big failure because even though the duplex has a relatively small total living space, it consists of...
67	128	1	2	Flips Ahoy in South Amboy	Jon and Michelle work with their project managers to update an outdated single-family home into a modern retreat in only 24 hours, and they contend with a broken sewer pipe, missing floors and...
68	131	37	18	Episode #37.18	A returning champion and two challengers test their buzzer skills and their knowledge in a wide range of academic and popular categories as they vie for a cash prize in the classic trivia game...
69	132	23	83	Episode #23.83	Two families composed of five members each compete against each other in a contest to see who can match more of their answers to survey questions with the most popular answers to the same...
70	132	23	85	Episode #23.85	Two families composed of five members each compete against each other in a contest to see who can match more of their answers to survey questions with the most popular answers to the same...
71	134	5	17	The Career Girl	Erin has graduated from high school, but just as she was before graduating, she still has no direction where she wants her life to head, taking advice from anyone she can get to either go to...
72	134	5	18	The Hero	John-Boy plans a gathering to salute the members of the county involved in World War II, but when he seeks help to plan it all out, he gets a less-than-interested response from the...
73	134	5	19	The Inferno	John-Boy makes a trip out to Lakehurst, New Jersey, to deliver a report about the landing of the Hindenburg; Curt tries to seek more alone time with Mary Ellen to keep the feelings between...
74	136	5	4	The Silent Bell	A pastor attempts to change the decision of the church, which wishes for him to begin teaching lessons of religion within his preschool, and his belief in respect for other cultures stops him...
75	136	5	5	The Reunion	Mark Gordon goes to his five-year class reunion only to find out that the joyous occasion is far from what he expected it to be, and the prom queen ironically happens to feel extremely out of...
76	137	8	19	Day of the Dead	The theft of a priceless artifact from a Mexico City museum leads Jessica into a labyrinth of clues where murder is the fact behind the Mask of Montezuma.
77	137	8	20	Angel of Death	While Jessica is in California to console a well-known playwright haunted by his wife's suicide, another family is murdered.
78	137	8	15	Tinker, Tailor, Liar, Thief	Jessica finds herself involved in a cover up for a British Intelligence operation which involves a double murder; she claims to have found a dead body in her hotel room in London but after it...
79	140	2	6	From Scary to Stunning	The road trip comes to an end as Retta reveals the winner of the Scariest House in America, which receives a $150,000 home renovation from HGTV's Alison Victoria, transforming their once scary...
80	141	13	6	Thin Margins	As the survivalists find a brief window to regroup and refocus, the Arctic continues to test their resolve; one participant gets their chance at big game, while another faces a lynx who puts...
81	142	1	8	Supersized Deadfall Trap	Previous contestants come back to take on a unique challenge and build massive deadfall traps with only a limited number of tools, all before being judged in the moment by expert survivalist...
82	143	4	14	The Reverend Steps Out	Chrissy catches her father spending time with an unfamiliar woman and assumes that he is cheating on her mother; Reverend Snow has a chance at a new job in Santa Monica, but it requires that...
83	143	4	15	Larry Loves Janet	Larry attempts to woo "nice girl" Janet after she comforts him following a particularly unsuccessful date, and Janet attempts to change Larry's mind about her by transforming herself into the...
84	143	4	16	Mighty Mouth	Jack attempts to impress a woman who works at a health spa by pretending to be athletically gifted, but problems soon arise when he buys a membership and the woman's overprotective,...
85	143	4	17	The Love Lesson	After catching Jack kissing a woman and then being told a lie to cover up, Mr. Furley begins to believe that Jack is becoming attracted to the opposite sex and offers to give his tenant a few...
86	144	10	14	Cul-de-sac	After the murder of Johnny Soekhies in Alabama, authorities turn to CCTV to hunt his killer, and the footage reveals a vehicle driving Johnny to the place of his eventual murder and captures a...
87	145	6	5	Risking it All	In New Mexico, a car chase ends dramatically with lasting consequences for a lieutenant, and a lone officer must keep her cool to safely detain a homicide suspect. In California, officers...
88	144	1	5	View to a Rampage	A newly engaged couple is brutally murdered in an abandoned parking lot in Irvine, Calif., and as the investigating officers set out to bring the killers to justice, they must rely on the only...
89	146	5	18	Family Matters	When the squad begins to investigate a case that involves a wife having found her husband murdered, some of the evidence that they begin to uncover seems to point to the wife having lived a...
90	146	6	1	The Platform	When a member of the team appears to have shot an unarmed man on a Boston subway platform, they have to race against an Internal Affairs investigation in order to find the true killer, but the...
91	149	4	6	Float Your Boat	The ladies are assigned colors to work with off of the rainbow flag for a pride parade runway challenge; after designing boats for an off-the-wall challenge, several of the ladies struggle to...
92	149	4	7	Dragazines	The ladies are given different magazine covers to recreate, but several of them struggle to find a cohesive design; the judges look for fun and funny magazine covers, but find several that...
93	149	4	8	Frenemies	After taking a lie-detector test, the ladies are paired up with each other based on the results and expected to sing a duet; several of the pairs showcase each other's talents, but others fail...
94	150	5	1	A Dream Come True	A family of four from Florida needs help renovating their dream home on a scenic lake in Maine if the cabin is going to be able to withstand the winter months and live up to their...
95	150	10	2	The Russell Cabin's Big Lift	The team tackles a fifth-generation cabin renovation in addition to staying busy with an ant invasion, a 1960s game show and a basketball showdown while adding bathroom privacy, a charming nap...
96	151	16	5	Small Town, Big Dreams	The Barnwood Builders construct a log cabin and timber frame in White Sulphur Springs, W.V., after a devastating flood wrecks the small town with big dreams.
97	152	7	9	Chanel and Sterling XXII	Model and actress Charlotte McKinney joins Rob, Sterling and Chanel to cover "Dirty Secrets," "All Natural Beef" and "Spike My Butt."
98	152	23	23	Chanel and Sterling CCCXCV	Rob, Chanel and Steelo check out "Summer Heated," "Snide Salads" and "DI-Why?"
99	152	48	6	Matthew Mounce	Rob, Chanel and Sterling present viewers with a series of comedic and outlandish video clips taken from the Internet in segments like "Unnecessary Combos," "Stay Out of the Water" and "Who Put...
100	153	6	21	I, Stank Hole in One	Hilary butts heads with her co-host when she fills in on a popular national morning talk show; Ashley and Vivian team up for a tennis competition, while Philip and Will do the same for a golf...
101	154	4	8	I Was En Vogue's Love Slave	When a tabloid publishes a false story that names Marlon as the love slave of the all-female R&B group, En Vogue, the female quartet winds up filing a $25 million lawsuit against Marlon,...
102	154	4	9	Can I Get a Witness?	The entire family must be placed under police protection after Marlon has become the primary witness to a recent bank robbery, but despite the extra security, the culprit sends his brother to...
103	154	4	10	Ted's Revenge	Shawn's former boss, who has recently been released from a mental institution, sets out to exact his long-awaited revenge on the unsuspecting Shawn because he blames him for the devastating...
104	155	1	2	Rome's Sunken Secrets	Investigators discover traces of a crucial naval battle, using divers, an underwater robot and a crane, they haul a long-lost battleship relic to the surface, and reveal clues of how one...
105	155	1	4	Nero's Lost Palace	Buried beneath Rome lies a forgotten treasure, the Golden House, a vast palace built in the first century AD built by Rome's most notorious emperor, Nero; archaeologists investigate the fate...
106	155	1	1	Hidden Secrets of Pompeii	Archaeologists embark on new digs in the ancient city of Pompeii, to unravel the stories of the people that lived and died here, as they uncover clues from the tomb and venture into stiflingly...
107	156	1	6	Sharks Gone Rogue	Brazen attacks are targeting people, and some wonder if sharks are learning to crave human flesh.
108	157	2	20	The World of North America	The Hannas go on an adventure to meet cool, and cute, North American creatures.
109	158	1	23	The One with the Birth	Ross's big day to become a father arrives when Carol goes into labor, but trouble arises when he gets locked inside a closet alongside Susan and Phoebe; Rachel attempts to be flirtatious with...
110	158	1	24	The One Where Rachel Finds Out	Ross is away during a business trip to China, and Chandler accidentally lets slip Ross' secret feelings of romance towards Rachel; matters become more awkward than ever before when Ross...
111	158	2	1	The One with Ross' New Girlfriend	Rachel resolves to be patient and wait at the airport until Ross can return and learn that she knows about his feelings, but Ross steps off the plane with big news about a girlfriend; Phoebe...
112	159	4	23	Pups Save Luke Stars; Pups Save Chicken Day	When Luke Stars gets stuck on a mountain ledge on his way to Adventure Bay, he is unable to perform a song with Katie; Mayor Goodway's pet chicken Chickaletta, goes missing on Chicken Day and...
113	160	3	9	Pups Save a Dragon; Pups Save the Three Little Pigs	When a dragon starts guarding the Lookout Tower with Katie inside, Ryder must enlist the help of the Pups and the Air Patroller; the PAW Patrol must build a new home for three piglets while...
114	160	4	22	Sea Patrol: Pups Save a Frozen Flounder; Sea Patrol: Pups Save a Narwhal	Captain Turbot's boat becomes frozen in ice while sailing in the Arctic; the PAW Patrol pups use their Sea Patroller to help guide a lost narwhal back to its home.
115	161	4	22	Sea Patrol: Pups Save a Frozen Flounder; Sea Patrol: Pups Save a Narwhal	Captain Turbot's boat becomes frozen in ice while sailing in the Arctic; the PAW Patrol pups use their Sea Patroller to help guide a lost narwhal back to its home.
116	161	2	21	The Crew Builds a Winter Wonderland; Crew Builds a Giant Snow Squirrely Whirly	Rubble & Crew work together to transform Builder Cove's beach boardwalk into a bright, festive, winter wonderland; when a snowy day gets in the way of Motor & Mix's Super Squirrely Whirly...
117	160	4	10	Mission PAW: Pups Save the Royal Throne	When sweetie has come up with plans in order to steal the royal throne so that she can rule, the pups must work together to save the day.
118	162	2	27	Pre-Hibernation Week; Life of Crime	Sandy invites Spongebob Squarepants to join her on her last week of wild fun before she has to settle in for hibernation; Spongebob and Patrick face the consequences of their negligence after...
119	163	15	2	UpWard; Unidentified Flailing Octopus	Lady Upturn introduces Squidward Tentacles and his musical talents to her high society friends after she becomes his patron; Squidward Tentacles sets out to prove that aliens aren't real,...
120	163	2	21	Your Shoe's Untied; Squid's Day Off	SpongeBob SquarePants forgets how to tie his shoelaces and has difficulty finding someone to show him how to do it; Squidward takes advantage of his responsibility of being in charge of Krusty...
121	163	6	7	Giant Squidward; No Nose Knows	Squidward turns into a giant when he gets sprayed with a plant growth formula, and word spreads through town that a new monster has arrived; Patrick decides that he wants a nose so he can...
122	164	2	2	Fashion	Three accomplished fashion designers, each exhibiting the sort of creativity that's required to succeed in today's industry, reveal their respective approaches to their work, from "green"...
123	167	7	3	Some Like It Hotter	A couple who won $1 million from the New York lottery has decided to purchase a home in the city of Punta Gorda, Fla., so they attempt to buy their way into a classy retirement village with...
124	167	7	5	Fort Worth Fortune	A professional poker player and his family have decided to purchase a home in the city of Fort Worth, Texas, so host David Bromstad helps them find a property that boasts plenty of space to...
125	167	7	7	Delaware Dream Home	Host David Bromstad shows a variety of remarkable homes to a Staten Island couple, who won the lottery and want to purchase a forever home in the city of Bethany Beach, Del., where they hope...
126	168	10	7	Close-Knit Clan	A couple and their four children found a way to squeeze themselves into a 1,200 square foot bungalow five years ago, but now the lack of bedrooms and space has become a detriment, and they...
127	171	6	5	Sacrifice	The team faces the demands of a kidnapper who abducted the director of a Brooklyn migrant center and his wife; Maggie uses Jessica to learn more about the ins and outs of motherhood.
128	171	6	6	Unforeseen	A poison gas attack in broad daylight leaves multiple victims dead as the team races to find those responsible before they can strike again.
129	171	6	7	Behind the Veil	After a restaurant bombing leaves a congresswoman among the victims, the team is tasked with tracking down the ones responsible before they can strike again.
130	172	4	82	Armed Carjacker	Clayton County officers search for an armed carjacking suspect; Toledo officers race to shots fired.
131	173	6	7	Blaze of Winston-Salem	A catastrophic fire at a fertilizer plant threatens city-wide devastation in Winston-Salem, N. C.; experts use the latest science to investigate and uncover an outdated, wooden storage...
132	175	13	7	Terror in Paradise	A plane of an airline linking the islands of French Polynesia leaves Moorea Island for Tahiti, but two minutes out it suddenly dives into the ocean, killing all 20 people on board, and its...
133	175	3	2	Attack Over Baghdad	On November 22, 2003, insurgents in Iraq fire a missile at an Airbus A300 air freighter owned by European Air Transport and flying for DHL Aviation; the hit destroys its hydraulic system and...
134	176	9	10	Hate	Newly-discovered evidence will point the investigating detectives in the direction of a fascist youth gathering after the brutal beating and murder of a high school girl, but the teenagers are...
135	176	9	11	Ramparts	Detectives Lennie Briscoe and Rey Curtis will have to reopen a case that was previously closed in the 1960s when they discover a vehicle dredged in the waters of the Hudson River containing...
136	177	5	22	If I Had a Quarter-Million	Barney's discovery of a bank satchel containing an ample allowance of stolen currency leads to his ambitious attempt to lure the furtive robbers to justice by using their own illicit loot,...
137	179	2	17	Personal	Detective Deeks has his morning routine disrupted when he is shot during a convenience store robbery, leaving the NCIS team to investigate into the fact whether the assailants' intentions were...
138	179	2	18	Harm's Way	Sam resumes a former alias he once had and boards a one-way flight to Yemen with Callen in hopes tracking down a dangerous leader of a terrorist group and safely rescuing the hostage son of a...
139	180	6	10	Murder	Michael finds himself unsettled after he hears some troubling rumors about Dunder Mifflin, and he forces the office into a day of strange diversions that leads everyone to wonder if he has...
140	180	6	11	Shareholder Meeting	Michael is excited to get the chance to be honored on stage at the Dunder Mifflin shareholder meeting, and he decides to bring Andy, Dwight and Oscar along with him; Jim has a hard time...
141	180	6	12	Scott's Tots	Michael is forced to face the music after he comes to the realization that he can't keep a promise that he made to a group of kids 10 years ago; Jim starts an employee of the month program in...
142	180	6	13	Secret Santa	Michael becomes outraged after Jim decides to let Phyllis take on the role of Santa at the office Christmas party; Jim and Dwight try to get the holiday spirit going, despite some doubts from...
143	182	5	26	Appetite for Destruction; Frame on You	When Lily Loud starts misbehaving at home, Mom and Dad think her new preschool friends might be the cause; when Rusty is wrongfully suspended, the Action News Team leaps into action to clear...
144	183	6	4	The Taunting Hour; Musical Chairs	Lincoln convinces his teacher, Mr. Bolhofner, to join the Doo-Dads in order to get a better seat in class; after Lincoln tries to help Lynn get over a heckler at her soccer game, the Louds...
145	183	5	24	Fright Bite; The Loudly Bones	When a vampire moves into their town of Royal Woods, Lucy Loud must convince him to turn the Mortician's Club into vampires; Lisa Loud discovers that the dinosaur bones she found in her...
146	184	6	3	Ew! What Is That?	The large tumours on Jennifer's scalp have left her with bald patches. Plus, Adam hopes to get a diagnosis for more than 60 lumps covering his body.
147	185	2	3	She's All MILF	A double date leads to awkward situations for two contestants; Barby and Jacob grow closer; one contestant has her secret exposed.
148	186	4	4	Baby Blues	Lilly brings up a family's suppressed and depressing memories when she reopens a case from 1982 in which an infant was found dead due to the possible actions of the older brother, who...
149	186	4	5	Saving Sammy	A shocking twist is uncovered from the 2003 case of an autistic boy's murdered parents when Lilly and her team of investigators find clues that surprisingly point to his sister, a school bully...
150	186	4	6	Static	Heads are turned and beliefs are shattered when a former celebrity DJ's death in 1958, which was labeled a suicide for years, is discovered to have been a murder; Scotty attempts to reach out...
151	187	10	1	The Haunted Pub of Doncaster and More	The owner of the Plough Inn in Doncaster, England, named Jane Bushell, claims to have captured footage of a destructive spirit wreaking havoc; footage of a Sasquatch-like creature and...
152	187	9	8	Bigfoot in Great Britain and More!	A bushcraft expert in Britain claims to have encountered a bigfoot-like creature; a simple walk down Route 66 in Arizona turns terrifying; three men in Argentina find something receding in a...
153	187	10	2	A Spirited Infirmary in Indiana and More	Two investigators feel unwelcomed by spirits at an abandoned Indiana infirmary; a high-flying cryptid gives a chilling warning in Chicago; a woman in Mexico is shocked to see her painting come...
154	188	1	153	The Alliance	One Joker is an avid photographer; there are some words that the guys never want to hear before a punishment; one Joker is never afraid to strip down.
155	188	1	155	Sorry for Your Loss	One Joker brought a kitten to the set, and the person responsible for the song used on the show is revealed; Q tried to master an instrument before the show.
156	189	4	21	The Smelly Car	Jerry and Elaine try to discover the origin of a mysterious and pungent odor left in Jerry's car, which they trace back to a valet from a local restaurant; George becomes interesting in Susan...
157	189	4	22	The Handicap Spot	An angry mob trashes Frank's car when George parks it in a handicap spot; the gang splits the cost of a big screen TV for the Drake's wedding; Kramer falls in love with a woman at a hospital...
158	189	5	1	The Mango	Jerry begs Elaine for another chance when he finds out she faked her orgasms; George tells Jerry about his lack of confidence below his belt; Kramer gets banned from his favorite fruit shop...
159	96	5	9	Comedy of Errors	The unexpected death of a schoolmate will prompt the shocked Dorothy to renew her long-time interest in performing stand-up comedy, but she almost causes a serious injury to herself after...
160	190	1	10	The Pineapple Incident	After a night of wild partying, Ted wakes up to find he has a sprained ankle, and that a burnt jacket, a pineapple and a girl are in his bed, so he requests the help of his friends to piece...
161	191	6	3	Skylar Diggins; Vic Mensa	WNBA star Skylar Diggins competes; rapper Vic Mensa performs.
162	191	6	4	Bow Wow; Que	Nick Cannon and rapper, actor, TV host Bow Wow face-off in "Let Me Holla," "Plead the Fifth," "Exclusive Hits" and "Wildstyle"; rapper Que performs.
163	191	6	5	Chrissy Teigen; PWD	Model Chrissy Teigen battles in "Got Props," "The World's Worst," "Talking Spit" and "Wildstyle"; hip-hop's Psych Ward Druggies perform.
164	191	6	6	Austin Mahone	Pop, R&B artist Austin Mahone battles Nick Cannon in "Turn Up For What," "Instaham," "Remix" and "Wildstyle."
165	193	2	5	S.O.S.	Hondo and Lina are undercover to infiltrate and retrieve a cruise ship that has been attacked by drug smugglers who threaten to kill passengers; Street finds the competition in the SWAT...
166	193	2	6	Never Again	The team pursues an organized group of thieves who target diamond dealers across downtown Los Angeles; Hondo seeks his mother's comfort after the emotional death of a suspect; Street is...
167	194	1	2	Healing Takes Time	The family gathers to share their feelings and memories during grief counseling to cope with the loss of Traci but when emotions run high and a family member suddenly leaves the session, Miss...
168	195	4	22	Hurricane Hampered	As Palm Beach, Fla., prepares for the incoming impact of Hurricane Andrew, a mother and her daughter are suddenly murdered in their home so the police team up with a forensic meteorologist to...
169	195	5	9	Burned in a Blackout	Some time after Hurricane Ivan arrives and wreaks havoc across the state of Alabama, emergency responders discover a woman's charred remains hidden deep beneath the rubble and wonder how she...
170	196	2	2	The Galveston Hurricane of 1900	A historical look is taken into the dramatic events surrounding the destruction of a hurricane that struck Galveston, Texas, in 1900, as experts believe it was more powerful than disasters...
171	197	3	5	Unbowed and Unbent	As the search for Aemond and Vhagar continues, Daemon attempts to control the spiraling situation in King's Landing.
172	198	3	5	Unbowed and Unbent	As the search for Aemond and Vhagar continues, Daemon attempts to control the spiraling situation in King's Landing.
173	203	2	8	International Assassin	Kevin makes a strong-willed effort to rid himself of Patti and her influence on an unexpected field of battle, where a shocking, heart-rending choice is the definitive action that stands...
174	203	2	9	Ten Thirteen	A personal loss that left Meg irreconcilable motivates her pilgrimage to Miracle to find shelter and offers leads to why she decided to become an advocate for the Guilty Remnant; Tom hopes to...
175	203	2	10	I Live Here Now	No longer driven to keep the secret, Kevin is honest with a suspicious John about his possible relationship to the disappearance of Evie; Miracle is confronted by an unforeseen threat on the...
\.


--
-- TOC entry 5108 (class 0 OID 18036)
-- Dependencies: 223
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genres (genre_id, genre_name) FROM stdin;
1	News
2	Sport
3	Crime
4	Mystery
5	Thriller
6	Drama
7	Comedy
8	Documentary
9	Talk-Show
10	Reality-TV
11	Adventure
12	History
13	War
14	Action
15	Horror
16	Game-Show
17	Romance
18	Family
19	Animation
20	Sci-Fi
21	Music
22	Short
23	Fantasy
24	Musical
25	Biography
26	Western
\.


--
-- TOC entry 5109 (class 0 OID 18046)
-- Dependencies: 224
-- Data for Name: program_genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.program_genres (program_id, genre_id) FROM stdin;
1	1
5	1
5	2
9	3
9	4
9	5
9	6
15	7
15	6
17	7
19	8
25	1
25	9
27	1
27	9
31	1
31	10
31	9
32	7
32	9
34	8
34	3
47	1
47	2
47	9
48	1
48	2
48	9
50	1
50	2
52	1
52	2
52	9
53	1
53	2
53	9
60	7
61	1
61	2
62	8
66	2
67	2
70	11
70	2
71	2
78	8
78	12
78	13
79	8
80	14
80	11
80	6
80	15
80	5
81	11
81	16
81	15
81	10
82	10
83	3
83	4
83	5
83	6
84	7
85	7
85	6
85	17
85	18
86	7
88	19
88	14
88	11
88	18
88	20
89	7
90	19
90	11
90	7
90	18
90	17
92	9
93	21
93	9
94	19
94	7
95	19
95	11
95	7
95	20
96	7
96	6
99	16
99	10
100	8
100	3
101	10
102	8
102	18
103	11
103	4
103	10
105	10
107	10
108	10
109	19
109	11
109	7
109	18
110	19
110	11
110	7
110	18
111	19
111	22
111	11
111	7
111	18
111	23
111	24
113	19
113	11
113	7
113	18
113	23
113	24
114	19
114	11
114	7
114	18
114	23
114	24
116	19
116	14
116	11
116	7
116	18
116	20
117	19
117	14
117	11
117	7
117	6
117	18
117	23
117	4
117	20
118	19
118	14
118	11
118	7
118	6
118	18
118	23
118	4
118	20
119	7
119	17
121	16
121	10
123	1
123	9
124	14
124	3
124	5
124	6
125	19
125	7
125	6
126	25
126	6
126	2
127	6
127	23
127	24
130	7
130	18
130	17
131	16
132	7
132	16
134	6
134	17
134	18
136	6
136	23
137	3
137	4
137	6
138	10
139	10
140	10
141	6
142	10
143	7
144	8
144	3
145	8
146	3
146	4
146	6
147	6
147	3
149	16
149	10
150	10
151	8
152	7
152	10
153	7
154	7
155	8
156	8
157	11
157	18
158	7
158	17
159	19
159	11
159	7
159	18
160	19
160	11
160	7
160	18
161	19
161	11
161	7
161	18
162	19
162	7
162	18
162	23
163	19
163	7
163	18
163	23
164	10
167	10
168	10
170	14
170	3
170	5
171	14
171	3
171	4
171	5
171	6
172	8
172	14
172	3
172	10
173	8
175	8
175	12
175	3
176	3
176	4
176	5
176	6
177	7
177	18
178	7
178	3
178	5
179	14
179	11
179	7
179	3
179	4
179	5
179	6
179	17
180	7
181	6
181	17
181	18
181	24
182	19
182	22
182	14
182	11
182	7
182	6
182	18
182	23
182	24
183	19
183	22
183	14
183	11
183	7
183	6
183	18
183	23
183	24
184	10
185	10
186	3
186	4
186	5
186	6
187	8
187	15
187	5
188	7
188	10
189	7
190	7
190	6
190	17
191	7
193	14
193	11
193	3
193	4
193	5
193	6
195	3
196	8
196	12
197	14
197	11
197	6
197	23
198	14
198	11
198	6
198	23
202	11
202	7
202	23
202	20
203	6
203	23
203	4
203	5
206	14
206	18
206	20
207	11
207	7
207	23
207	20
208	7
208	6
208	21
209	15
209	5
210	7
210	6
210	23
210	15
210	4
210	5
211	7
211	15
211	4
211	5
212	15
212	5
213	3
213	5
213	6
216	15
216	4
219	14
219	3
219	6
219	2
220	14
220	3
220	6
220	2
221	7
221	3
222	7
222	3
223	14
223	11
223	20
223	5
224	7
224	6
225	7
225	6
226	7
227	7
227	18
228	7
228	17
230	19
230	7
230	23
230	24
231	19
231	7
231	23
231	24
235	14
235	11
235	23
235	5
236	11
237	7
237	6
238	14
238	11
238	6
238	5
240	14
240	7
240	3
240	5
242	14
242	11
242	23
242	5
243	14
243	25
243	3
243	4
243	5
244	6
244	4
244	20
245	7
246	7
246	17
247	7
247	6
248	14
248	6
249	7
249	6
250	17
251	6
251	18
252	11
252	6
256	18
257	7
257	6
257	17
258	3
258	4
258	6
258	15
259	22
259	21
259	4
259	17
260	15
260	5
261	14
261	6
261	15
261	20
261	5
262	5
263	11
263	13
263	7
263	6
263	5
264	25
264	12
264	3
264	6
265	6
265	12
265	13
266	25
266	3
266	6
266	17
267	26
268	6
268	26
270	15
270	4
270	5
271	15
271	4
271	5
272	6
272	2
273	7
273	6
273	15
273	4
275	6
275	23
275	15
276	6
276	23
276	15
276	5
\.


--
-- TOC entry 5105 (class 0 OID 17998)
-- Dependencies: 220
-- Data for Name: program_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.program_types (program_type_id, type_name) FROM stdin;
1	movie
2	sports
3	family
4	news
5	other
\.


--
-- TOC entry 5106 (class 0 OID 18008)
-- Dependencies: 221
-- Data for Name: tv_channels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tv_channels (channel_id, call_sign) FROM stdin;
1	ABC
2	CBS
3	FOX
4	NBC
5	PBS
6	CW
7	MYNET
8	ION-E
9	TELMUN
10	UNI-E
11	BBCNW
12	BLOOMBERG
13	CNBC
14	CNN
15	CSPA-1
16	FOXBN
17	FNC
18	HLN
19	MSNBC
20	WGNAMER
21	ACCN
22	BTN
23	CBSSPT
24	ESPN
25	ESPN2
26	ESPNWS
27	ESPNU
28	FANDU
29	FS1
30	FS2
31	FUSEHD
32	GOLF
33	MTTREND
34	NFLNET
35	MLB
36	NBATV
37	NHLTV
38	OUTDRE
39	SECNET
40	TENNIS
41	A&E
42	AHC
43	AMCALL
44	ANIMAL
45	BBCAME
46	BET
47	BETHER
48	BOOM-E
49	BRAVO
50	TOON-E
51	CMTV
52	CMDY-E
53	COOKING
54	CRIMEINV
55	DESTAMER
56	TDC-E
57	DFCH
58	DLIF
59	DIS-E
60	DISNEYJR
61	DISNEYXD
62	ETV-E
63	FOODTV
64	FREEFRM
65	FX-E
66	FXX
67	FXM
68	FYI
69	GACFAM
70	GSN
71	HALMRK
72	HALLDRM
73	HALLMYS
74	HGTV
75	THC
76	IFC
77	ID
78	LIF-E
79	LMN
80	LOGO
81	MAGN
82	MTV-E
83	MTV2
84	NGC-E
85	NGEOWILD
86	NIC-E
87	NICKJR
88	NTOON
89	OVAT
90	OWN
91	OXGN-E
92	PARMT
93	POP
94	REELZ
95	SCIENCE
96	SMITHSON
97	SUN
98	SyFy
99	TBS
100	TCM
101	TEENNCK
102	TLC
103	TNT
104	TRAVEL
105	TRUTV
106	TVLAND
107	USA-E
108	VH-1E
109	VICE
110	WE
111	WEATH
112	HBOEAL
113	HBO2
114	HBOC-E
115	HBOSG
116	HBOZ-E
117	5STMAX
118	AMX-E
119	MAXEAL
120	MMX-E
121	ParSHO
122	SHO2XE
123	SHOBET
124	SHOX-E
125	SHOWFAM
126	SHOWNEXT
127	SHOCSE
128	SHOWWOM
129	FLIX-E
130	TMCEAL
131	TMC2XE
132	STARZ
133	STARZCIN
134	STARZCOM
135	STARZED
136	STARZBLK
137	STARZFAM
138	ENCORE
139	ENCORFM
140	ENCORSS
141	ENCRACT
142	ENCRBL
143	ENCRCL
144	ENCRWST
145	MGM+
146	MGM+DRV
147	MGM+HIT
148	MGM+MAR
\.


--
-- TOC entry 5107 (class 0 OID 18018)
-- Dependencies: 222
-- Data for Name: tv_programs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tv_programs (program_id, program_type_id, title, description, parental_rating) FROM stdin;
1	4	ABC World News Now	The hosts bring you overnight breaking news, weather, politics, and the stories and videos people will be talking about in the day ahead.	\N
2	4	CBS News Roundup	The members of the CBS News team highlight the top headlines of the day.	\N
3	5	Local Programs	Local programming information.	TV-14
4	5	Top Story with Tom Llamas	Anchor Tom Llamas offers an in-depth look at breaking news and major events in real time along with impactful interviews about social issues, race, finance and more from those affected most by...	\N
5	4	Early Today	A comprehensive, early morning look at the latest overnight news events from across the nation and around the world and includes regional and national weather forecasts, segments on business...	\N
6	5	Bugs That Rule the World	Scientists and other experts discuss bees, moths, butterflies and other essential pollinators to reveal how these creatures make a big impact on the planet despite their rather delicate...	\N
7	5	Breaking the Deadlock	Facing a gripping hypothetical dilemma-disinformation about a controversial school board decision spreading rapidly on social media-a panel of experts grapples with what is true, and what...	\N
8	5	Once Upon a Time in Space	When the Soviet Union falls, Russia welcomes U.S. astronauts to their space station, Mir. But co-operation between former Cold War enemies is threatened by a run of disasters onboard.	\N
9	5	Law & Order: Special Victims Unit	Rollins and Kat tend to a dangerous domestic violence call; Fin provides his deposition in the lawsuit against him.	TV-14
10	5	Inogen Portable Oxygen - No More Tanks!	Regain independence and enjoy greater mobility with the compact design and long-lasting battery of portable oxygen.	\N
11	5	Paid Program	Sponsored television programming.	G
12	5	En casa con Telemundo	Una entretenida mezcla de las noticias del entretenimiento, exclusivas con estrellas de la música, el cine y la televisión, presentaciones en vivo, y el estilo de vida de los famosos.	\N
13	4	En casa con Telemundo	Una entretenida mezcla de las noticias del entretenimiento, exclusivas con estrellas de la música, el cine y la televisión, presentaciones en vivo, y el estilo de vida de los famosos.	\N
14	4	La mesa caliente	Un equipo de mujeres audaces y empoderadas, debate desde diversas perspectivas sobre el entretenimiento, los temas más candentes y controversiales que afectan a la comunidad latina en...	\N
15	5	Como dice el dicho	Recreación de múltiples historias basadas en refrán popular en las que intervienen, Don Tomás, un hombre bonachón de más de 60 años, que es el dueño del Café Del Dicho al Hecho, y su nieta...	TV-14
16	5	Desiguales	El show que reúne a cinco bellas mujeres con perfiles e historias de vida contrastantes, quienes nos presentan los temas más candentes con sus criterios personales, a través de una...	\N
17	5	Vecinos	Problemas, complicaciones, enredos y situaciones cómicas que surgen entre los vecinos que viven en un complejo de apartamentos, a causa del roce diario entre los inquilinos.	TV-PG
18	5	Business Today	A comprehensive first look at the latest news from the business world is provided by a team of news anchors, along with the latest analyses and predictions that affect the British business...	\N
19	5	Talking Movies	Host Tom Brook takes an in-depth look at recent developments in the world of cinema, meeting with the best in the business, offering behind-the-scenes reports, and showcasing highlights from...	TV-PG
20	4	BBC News	The latest news from the BBC.	\N
21	5	Bloomberg: The Opening Trade	Hosts Anna Edwards, Guy Johnson and Kriti Gupta break down the biggest stories of the day as markets open around Europe, with astute analysis and guests with stakes in the game.	\N
22	5	The Pulse with Francine Lacqua	Based in London, Francine Lacqua engages in conversations with top guests in global business, economics, finance and politics.	\N
23	5	Dateline	Questions arise when the glamourous life of a model comes to a violent end and she is found floating face down at the bottom of her Florida home's pool, her body beaten and her children...	TV-14
24	5	Squawk Box (Europe)	Host Geoff Cutmore and market watchers Steve Sedgwick and Louisa Bojesen provide the latest information on stocks and business reports in Europe; financial experts weigh in on recent...	\N
25	5	Anderson Cooper 360°	Anderson Cooper reports on breaking news from around the world, providing an in-depth look at headline news as well as the underreported events of the day, with medical commentary from Dr...	\N
26	4	CNN NewsNight with Abby Phillip	Political correspondent Abby Phillip presents a sharp approach to the day's headlines.	\N
27	4	Anderson Cooper 360°	Anderson Cooper reports on breaking news from around the world, providing an in-depth look at headline news as well as the underreported events of the day, with medical commentary from Dr...	\N
28	4	U.S. House of Representatives	The House will complete work on the 2027 defense programs and policy (NDAA) bill and consider the GOP budget resolution for reconciliaiton 3.0 and legislation to ban stock trading by members...	\N
29	5	Best Mattress Topper Ever!	Back Pain? Hip? Sleep well thanks to this cooling topper!	G
30	5	Kelsey Grammer's Historic Battles for America	The Virginia hills run red with blood during the Battle of Bull Run, the first major battle of the American Civil War, and the fighting dashes all hopes for a swift end to the war as the...	\N
31	5	Hannity	The noted author and commentator brings his perspective to today's top news stories and presents segments such as "The Great American Panel," with three guests offering point and counterpoint...	\N
32	5	Gutfeld!	Host Greg Gutfeld discusses the latest news stories, entertainment updates and current events through a presentation of comedic parodies, panel discussions, monologues, and interviews with...	\N
33	5	Fox News @ Night	Anchor Shannon Bream presents viewers with a look at the latest news stories and featured headlines of the day, with commentary from a selection of correspondents and experts, and an eye...	\N
34	5	Forensic Files	When police investigators experience difficulty solving crimes, they seek the assistance of scientists who are able to uncover clues through the close examination of evidence using the most...	TV-14
35	5	The 11th Hour with Ali Velshi	Ali Velshi delivers sharp, data-driven analysis of the day's stories in economics, politics, democracy and foreign affairs. In the heart of NYC, Velshi convenes a panel of guests to help...	\N
36	4	All in with Chris Hayes	Commentator Chris Hayes discusses numerous political issues and important topics of the day with a panel comprised of noted experts.	TV-PG
37	4	The Briefing with Jen Psaki	Political analyst Jen Psaki examines the biggest issues of the week and interviews newsmakers.	\N
38	5	Katie Pavlich	\N	TV-PG
39	4	Cuomo	The day's major news events affecting the city, the state, and the nation, along with late-breaking stories from around the globe and interviews with a special guest, are presented by Chris...	\N
40	4	On Balance with Leland Vittert	The day's major news events affecting the city, the state, and the nation, along with late-breaking stories from around the globe, are presented by Leland Vittert.	\N
41	5	College Football	Miami Hurricanes at Florida State Seminoles from Doak S. Campbell Stadium	\N
42	2	ACC Huddle	Analysts preview the 2025 football season for the Wake Forest Demon Deacons, breaking down the key players returning from last year's team, the newcomers that will have some shoes to fill from...	\N
43	2	Authentic ACC	An all-access look focuses on the Wake Forest football team as they prepare for the 2025 season during the spring practice session, as interviews with head coach Jake Dickert and star players...	\N
44	2	College Baseball	Minnesota Golden Gophers vs Purdue Boilermakers from TD Ameritrade Ballpark in Omaha, Neb.	\N
45	5	2026 SBD World's Strongest Man	\N	\N
46	2	2026 SBD World's Strongest Man	\N	\N
47	5	SportsCenter	The worldwide leader in sports covers all the important stories of the day, including game highlights, player interviews, and special segments; correspondents relay up-to-the-minute news and...	\N
48	2	SportsCenter	The worldwide leader in sports covers all the important stories of the day, including game highlights, player interviews, and special segments; correspondents relay up-to-the-minute news and...	\N
49	2	The 2026 ESPYS	from David H. Koch Theater in New York City	\N
50	5	NFL Live	The latest news and reports around the NFL are discussed in detail with a panel of expert analysts weighing in on the hottest issues, while veteran football reporters provide up-to-date...	\N
51	2	MLB Baseball	Detroit Tigers at Chicago Cubs from Wrigley Field	\N
52	5	Pardon the Interruption	Tony Kornheiser and Michael Wilbon, longtime colleagues and friends, engage in verbal sparring during a fast-paced and wide-ranging discussion about current events in the world of sports;...	\N
53	2	Donk Toss World Championship	Tony Kornheiser and Michael Wilbon, longtime colleagues and friends, engage in verbal sparring during a fast-paced and wide-ranging discussion about current events in the world of sports;...	\N
54	2	BBA Bubbleball	\N	\N
55	2	College Football	Texas A&M Aggies at Texas Longhorns from Darrell K Royal-Texas Memorial Stadium	\N
56	2	Live Racing! International	Live horse racing from various tracks from across the globe.	\N
57	2	The Basketball Tournament	from Memorial Coliseum in Lexington, Ky.	\N
58	5	2026 FIFA World Cup	Norway at England from Miami Stadium	\N
59	2	2026 FIFA World Cup	France at England from Miami Stadium	\N
60	1	Malibooty!	Determined to fulfill his lifelong dream of being a famed hip-hop star, a man convinces his friends to go with him to Malibu to crash the Boogie Beach Bash and make industry contacts, but they...	PG-13
61	2	Golf Central	Experts explore the latest news and reports surrounding the world of golf, including daily coverage from the biggest tournaments, live updates, highlights of top moments, in-depth analysis...	\N
62	5	Wheeler Dealers: World Tour	\N	\N
63	5	Team Highlights	NFL Films provides a detailed look back at highlights of all 32 teams from the 2013 season, featuring wired up players and coaches during the biggest matchups, memorable plays and moments that...	\N
64	2	Team Highlights	NFL Films provides a detailed look back at highlights of all 32 teams from the 2013 season, featuring wired up players and coaches during the biggest matchups, memorable plays and moments that...	\N
65	2	The Insiders	NFL insiders, including Ian Rapoport, Tom Pelissero and Mike Garafolo, break down the latest team news making headlines across the league, discussing the impact it will have on the team, along...	\N
66	5	Quick Pitch	Catch all the latest baseball news, scores and highlights plus your first look at upcoming matchups, all in one lightning-fast hour.	\N
67	2	Quick Pitch	Catch all the latest baseball news, scores and highlights plus your first look at upcoming matchups, all in one lightning-fast hour.	\N
68	2	The Association	Cameras give an all-access look at the top teams in the NBA throughout the season as they compete for a spot in the playoffs, showing the players and coaches on and off the court to show the...	\N
69	5	NHL Tonight	Updates from games taking place around the league as well as highlights, injury updates and postgame interviews with players and coaches; coverage includes discussion on the latest headlines...	\N
70	5	Bowhunter TV	Outdoor enthusiasts and professional hunters Mike Carney and Curt Wells give an in-depth examination of the bowhunting industry, while offering viewers helpful insider tips and features on the...	\N
71	5	Guns & Ammo TV	Firearms experts put today's best firearms through the torture test, provide reviews of brand new products as well as classic guns, and explore the latest news from the world of guns and gun...	\N
72	5	Handguns	Pistols, revolvers, ammunition and accessories used in a core handgun environment such as police service, home defense, competitive shooting and hunting are examined as veteran hosts display...	\N
73	5	Shooting USA	Firearms reporter and host Jim Scoutten travels around the country while providing reports from the firearms development field, delving into the history of guns and gun-making, and delivering...	\N
74	2	SEC Now	from Tampa Marriott Water Street, Tampa, FL, USA	\N
75	2	The Paul Finebaum Show	Paul Finebaum shares his thoughts on the latest college football news, offering his insight on the latest issues, and he interviews various guests about current events; Finebaum takes calls...	\N
76	2	Courtside	Coverage of ATP 250 clay court tournaments in Kitzbuhel and Estoril as well as a WTA 250 clay court tournament in Hamburg; Prague is hosting a WTA 250 hardcourt tournament before the North...	\N
77	5	Swamp Patrol	In Arkansas, multiple units search for a suspect in thick woodland. A brave police dog jumps off a 60-foot bridge. A man hiding in swamp mud gets stuck. A car crashes into a lake with a child...	\N
78	5	Against the Odds	A detailed examination of the paratroopers of Fighting Fox Company, who fought and died in World War II battles from Normandy to Hitler's Eagle's Nest, demonstrating both dogged determination...	TV-PG
79	5	Shadow Ops	Oleg Gordievsky, colonel in the KGB, the Soviet's Committee for State Security, spends ten years spying for Britain's Secret Intelligence Service when he discovers that the Soviets are...	TV-PG
80	5	The Walking Dead: Dead City	Once Maggie finds Negan, they travel to Manhattan; Negan is followed by a marshal named Armstrong; a quiet girl named Ginny.	TV-MA
81	5	Naked and Afraid	Legendary survivalists Max and Rylie join two novice fans in the South African bush, where they must survive for three weeks among spitting cobras, aggressive warthogs, rhinos and...	TV-14
82	5	My Cat from Hell	After a desperate woman posts a video looking for a home for her problematic cat Jimmy Slap, Jackson is called in to offer her the help she needs; Harold the cat wants to kill fellow feline...	TV-PG
83	5	Criminal Minds	Prentiss feels that she is ready to finally confront her nemesis, Ian Doyle, once and for all; the BAU team calls upon their beloved former team member in JJ to help them find Prentiss and...	TV-14
84	5	The Jamie Foxx Show	Jamie and the family attempt to have a nice Thanksgiving dinner but when an unexpected accident befalls the head of the household the entire day is ruined with they are forced to go to the...	TV-PG
85	5	Tyler Perry's House of Payne	Ella faces a frightening health situation after her annual mammogram reveals she has a lump in her breast; Malik's scholarship hangs in the balance when he faces the difficult choice between...	TV-PG
86	5	Tyler Perry's Assisted Living	Mr. Brown's girlfriend is furious to learn Anastasia is competing in the same pageant as her; Leah is shocked when Jeremy buys her a broom for a birthday gift.	TV-PG
87	5	Reminisce	A throwback mix of R&B and hip hop music to start the morning.	TV-14
88	5	Ben 10	A magician whose intimidating powers originate from within a set of mystical charms faces off against Ben in a battle that becomes increasingly ominous for the villain when his foe uses the...	TV-Y7
89	5	Tom and Jerry	Tom and Jerry try to do each other in during a fishing trip.	TV-PG
90	5	Popeye the Sailor	Bluto checks himself into the hospital to fake exhaustion so that he can get some rest and enjoy some peace and quiet, and when Popeye discovers what Bluto is up to, he plays a trick on his...	PG
91	5	Next Gen NYC	Shai and Rowan host a Halloween party in Brooklyn where Shai and Charlie put Liam in the hot seat. Ariana confronts Shai for meddling in her love life. Emira attempts to end "flirt-gate" by...	\N
92	5	Watch What Happens: Live	TV personalities Ariana Biermann and Kristen Doute.	TV-14
93	5	The Kelly Clarkson Show	Grammy Award-winning artist Kelly Clarkson interviews some of the biggest stars in the entertainment industry, spotlights individuals who have made a difference in their communities, and...	\N
94	5	American Dad!	Francine promises to take Klaus down because she is jealous of his improvements.	TV-14
95	5	Rick and Morty	Morty and Summer go to camp, broh. Beth and Jerry home alone, broh.	TV-14
96	5	The Golden Girls	Blanche and Dorothy create a fictional admirer to answer Rose's personal ad, but the meddlesome roommates are left scrambling when she decides to invite who she believes to be her imaginary...	TV-PG
97	5	CMT Music	CMT presents a selection of music videos from some of the hottest country music artists, showcasing a block of back-to-back hits performed by up-and-coming country music stars, as well as...	TV-PG
98	5	South Park	The town of South Park suddenly takes on the look of Japanese anime; Butters is horribly wounded when Stan, Kyle, Kenny and Cartman become warriors and conspire to purchase dangerous, illegal...	TV-MA
99	5	Kids Baking Championship	Valerie Bertinelli and Duff Goldman ask the remaining bakers to incorporate chilies, peppers, and cayenne into the chocolate items the bakers prepared causing the kids to be able to balance...	\N
100	5	Cold Case Files	A college student disappears from his graveyard shift at a gas station; new forensic technology and the discovery of an illegal drug ring in a squeaky-clean town helps police solve the case...	TV-14
101	5	BBQ Pitmasters	The competition pits potential Pitmasters against one another in Salisbury, Md., where Purdue Chicken got its humble start, which is why the competitors are tasked with creating various...	TV-PG
102	5	Beachfront Bargain Hunt	A family of five who enjoys spending time in Galveston, Texas, wants to find peace and quiet in the nearby city of Jamaica Beach, Texas, so they're on the hunt for a turnkey abode that boasts...	\N
103	5	Expedition Unknown	Host Josh Gates investigates one of the most mysterious airline disasters in the history of the United States as he attempts to uncover why Northwest Flight 2501 seemingly disappeared out of...	TV-PG
104	5	Hustlers Gamblers Crooks	A mortgage fraudster steals millions and reconstructs his face to avoid the FBI.	\N
105	5	Food Paradise	A basic burger in Las Vegas costs only seven dollars, a wasabi mashed potato burger serves a unique taste and a huge backyard barbecue masterpiece is on a bun.	\N
106	5	Bakery Boss	Visiting a bakery run like a soap opera, full of drama and spice.	TV-PG
107	5	Kitchen Crashers	Alison and the crew find a couple that is very much into art and they want a kitchen to match their style; after a full demo, new cabinets in two finishes, white countertops, lighting, and...	\N
108	5	My 600-lb Life	After quitting his drug addiction, a man instead became addicted to food and soon found himself unable to stop even as he continues to put on weight.	TV-PG
109	5	Big City Greens	Gloria's café has a perfect rating, and she works hard to keep it that way until someone gives her a B rating; Bill drags his family along on a blackberry picking adventure and enforces a...	TV-Y7
110	3	Big City Greens	A wild child needs Cricket's guidance, so he steps up as a mentor and Tilly develops a loyal underground following; Nancy works to prove she can be useful on the farm while Bill tries and...	TV-Y7
111	3	Kiff	Kiff discovers the burdens of leadership while leading a group to the mall for free pretzels; Kiff and Barry hope to learn about the mysterious Ghost Wolf.	TV-Y7
112	5	BeddyByes	Join MeMo and BaBa as they encounter all kinds of fantastical beings that encourage good nutrition, mindfulness and creativity, all the while winding down towards sleep.	\N
113	5	Disney's Mickey Mouse Clubhouse	Mickey and the rest of the friends assist Goofy with completing his food deliveries for his lunch truck, which he calls "Chef Goofy on the Go."	TV-Y
114	3	Disney's Mickey Mouse Clubhouse	When Professor Von Drake introduces Mickey and his friends to a new innovative sport, the ball they're using gets away from them, so they are forced to change their playing field to the...	TV-Y
115	3	Bluey	Mum encourages the family to play musical statues; Indy feels disappointed in her model horse, but her pals encourage her to not give up; Bluey and Bingo teach Unicorse good manners so that he...	TV-Y
116	5	Big Hero 6	Lacking certain members, the team tries to prevent Noodle Burger Boy from achieving his goals while he is aided by his new family.	TV-Y7
117	3	DuckTales	Donald and Penumbra are forced to figure out how to escape from Moon Prison before they can warn planet Earth about an impending invasion; Dewey and Webby happen upon an evil conspiracy that...	TV-Y7
118	3	Amphibia	Sprig hopes to spend more time with Hop Pop while the family is out on a fishing trip, but one of Hop Pop's friend keeps getting in the way; Anne loses her music box while explores the strange...	TV-Y7
119	1	Royal Rendezvous	A chef from eastern Los Angeles is offered to visit Ireland and cook a royal feast meant to distract a Lord's grandmother from selling a cherished manor, which leads to unexpected romances...	\N
120	1	Arranged Love	A woman fled an arranged marriage and left her inheritance behind to run her own startup, but when a problem threatens her company, she decides to pretend to be married to a man so she can...	\N
121	5	Guy's Grocery Games	Three restaurant crews featuring family and longtime employees compete.	\N
122	5	What’s Your Injury Case Worth?	Legal professionals standing by 24/7. Call now for your free case evaluation!	G
123	5	The 700 Club	Host and Reverend Pat Robertson joins a panel of guests for a discussion of religious commentary on news events, featured stories, contemporary music, interviews, testamonies, politics, the...	\N
124	1	Man on Fire	An aging and cynical former-government agent is recruited by a wealthy couple in Mexico City to help protect their little girl from kidnappers, and he soon begins to grow close to the girl and...	R
125	5	King of the Hill	The Arlen City Council's ban on foods containing trans-fats leads Hank to get involved in a dirty battle between two rival lunch trucks that are trying to traffic their tasty, unhealthy fare...	TV-PG
126	1	Big George Foreman: The Miraculous Story of the Once and Future Heavyweight	Former boxer George Foreman finds his faith, retires and becomes a preacher but when financial hardship hits his family and church, he steps back in the ring and regains the championship at...	PG-13
127	1	Carousel	A wild carnival barker with a penchant for getting into trouble falls in love with and marries a beautiful factory worker, but their relationship doesn't go smoothly after he loses his job and...	G
128	5	24 Hour Flip	Michelle and Jon work on a monstrous house as they venture outside of their comfort zone, and they have a hard time renovating the home's three bathrooms while also contending with supply...	TV-PG
129	1	A Royal Icing Christmas	Princess Charlotte of Marovia escapes the palace to pursue her passion for cooking; she enters a Christmas baking contest under an alias, where she finds love-and the courage to embrace her...	\N
130	1	Christmas on Candy Cane Lane	A town cop is excited to celebrate her first Christmas in her new home, until she finds out that her neighbors expect her keep up the holiday tradition of going all out on holiday home...	TV-PG
131	5	Jeopardy!	A returning champion and two challengers test their buzzer skills and their knowledge in a wide range of academic and popular categories as they vie for a cash prize in the classic trivia game...	\N
132	5	Family Feud	Two families composed of five members each compete against each other in a contest to see who can match more of their answers to survey questions with the most popular answers to the same...	TV-PG
133	5	Bath Makeover	Transform your bath affordably in just one day!	G
134	5	The Waltons	Erin has graduated from high school, but just as she was before graduating, she still has no direction where she wants her life to head, taking advice from anyone she can get to either go to...	\N
135	5	Heartland	Amy fights to keep Dexter in the family when she learns Tim is putting the horse up for sale in a claiming race.	TV-PG
136	5	Highway to Heaven	A pastor attempts to change the decision of the church, which wishes for him to begin teaching lessons of religion within his preschool, and his belief in respect for other cultures stops him...	TV-PG
137	5	Murder, She Wrote	The theft of a priceless artifact from a Mexico City museum leads Jessica into a labyrinth of clues where murder is the fact behind the Mask of Montezuma.	TV-PG
138	5	House Hunters	A couple with three children is feeling crowded in their current home and looking for more space in the Mojave Desert.	\N
139	5	Ugliest House in America	A Denver couple's moving to be closer to their son in Seattle. They want a place with plenty of room to entertain family, but high prices and their fear of gloomy weather is making it hard to...	\N
140	5	Scariest House in America	The road trip comes to an end as Retta reveals the winner of the Scariest House in America, which receives a $150,000 home renovation from HGTV's Alison Victoria, transforming their once scary...	\N
141	5	Alone	As the survivalists find a brief window to regroup and refocus, the Arctic continues to test their resolve; one participant gets their chance at big game, while another faces a lynx who puts...	TV-14
142	5	Alone: The Skills Challenge	Previous contestants come back to take on a unique challenge and build massive deadfall traps with only a limited number of tools, all before being judged in the moment by expert survivalist...	TV-PG
143	5	Three's Company	Chrissy catches her father spending time with an unfamiliar woman and assumes that he is cheating on her mother; Reverend Snow has a chance at a new job in Santa Monica, but it requires that...	TV-PG
144	5	See No Evil	After the murder of Johnny Soekhies in Alabama, authorities turn to CCTV to hunt his killer, and the footage reveals a vehicle driving Johnny to the place of his eventual murder and captures a...	TV-14
145	5	Body Cam	In New Mexico, a car chase ends dramatically with lasting consequences for a lieutenant, and a lone officer must keep her cool to safely detain a homicide suspect. In California, officers...	TV-14
146	5	Rizzoli & Isles	When the squad begins to investigate a case that involves a wife having found her husband murdered, some of the evidence that they begin to uncover seems to point to the wife having lived a...	TV-14
147	1	Yoga Teacher Killer: The Kaitlin Armstrong Story	When a professional cyclist is found dead following a short-lived affair with a fellow athlete, all the clues point to the crime being an act of jealousy at the hands of a yoga teacher, who...	TV-14
148	1	Paid Program	Sponsored television programming.	G
149	5	RuPaul's Drag Race	The ladies are assigned colors to work with off of the rainbow flag for a pride parade runway challenge; after designing boats for an off-the-wall challenge, several of the ladies struggle to...	TV-14
150	5	Maine Cabin Masters	A family of four from Florida needs help renovating their dream home on a scenic lake in Maine if the cabin is going to be able to withstand the winter months and live up to their...	\N
151	5	Barnwood Builders	The Barnwood Builders construct a log cabin and timber frame in White Sulphur Springs, W.V., after a devastating flood wrecks the small town with big dreams.	\N
152	5	Ridiculousness	Model and actress Charlotte McKinney joins Rob, Sterling and Chanel to cover "Dirty Secrets," "All Natural Beef" and "Spike My Butt."	TV-14
153	5	The Fresh Prince of Bel-Air	Hilary butts heads with her co-host when she fills in on a popular national morning talk show; Ashley and Vivian team up for a tennis competition, while Philip and Will do the same for a golf...	TV-PG
154	5	The Wayans Bros.	When a tabloid publishes a false story that names Marlon as the love slave of the all-female R&B group, En Vogue, the female quartet winds up filing a $25 million lawsuit against Marlon,...	TV-PG
155	5	Lost Treasures of Rome	Investigators discover traces of a crucial naval battle, using divers, an underwater robot and a crane, they haul a long-lost battleship relic to the surface, and reveal clues of how one...	TV-PG
156	5	Shark Attack Files	Brazen attacks are targeting people, and some wonder if sharks are learning to crave human flesh.	TV-14
157	5	Jack Hanna's Passport	The Hannas go on an adventure to meet cool, and cute, North American creatures.	\N
158	5	Friends	Ross's big day to become a father arrives when Carol goes into labor, but trouble arises when he gets locked inside a closet alongside Susan and Phoebe; Rachel attempts to be flirtatious with...	TV-14
159	5	PAW Patrol	When Luke Stars gets stuck on a mountain ledge on his way to Adventure Bay, he is unable to perform a song with Katie; Mayor Goodway's pet chicken Chickaletta, goes missing on Chicken Day and...	TV-Y
160	3	PAW Patrol	When a dragon starts guarding the Lookout Tower with Katie inside, Ryder must enlist the help of the Pups and the Air Patroller; the PAW Patrol must build a new home for three piglets while...	TV-Y
161	3	Rubble & Crew	Captain Turbot's boat becomes frozen in ice while sailing in the Arctic; the PAW Patrol pups use their Sea Patroller to help guide a lost narwhal back to its home.	TV-Y
162	5	SpongeBob SquarePants	Sandy invites Spongebob Squarepants to join her on her last week of wild fun before she has to settle in for hibernation; Spongebob and Patrick face the consequences of their negligence after...	TV-Y7
163	3	SpongeBob SquarePants	Lady Upturn introduces Squidward Tentacles and his musical talents to her high society friends after she becomes his patron; Squidward Tentacles sets out to prove that aliens aren't real,...	TV-Y7
164	5	The Art Of	Three accomplished fashion designers, each exhibiting the sort of creativity that's required to succeed in today's industry, reveal their respective approaches to their work, from "green"...	TV-14
165	5	Have Thinning Hair? Keranique Can Help Regrow Beautiful, Thicker Hair!	If you have thinning hair or hair loss, Keranique can help regrow thicker, longer and fuller hair.	\N
166	5	The Aging Brain	Learn what's behind mental decline with age, and how to improve memory, focus and concentration with NeuroQ's Darrin Peterson and Dale Bredesen MD.	G
167	5	My Lottery Dream Home	A couple who won $1 million from the New York lottery has decided to purchase a home in the city of Punta Gorda, Fla., so they attempt to buy their way into a classy retirement village with...	\N
168	5	Love It or List It	A couple and their four children found a way to squeeze themselves into a 1,200 square foot bungalow five years ago, but now the lack of bedrooms and space has become a detriment, and they...	\N
169	5	The Killer Among Us	The First Baptist Church of Madisonville, Kentucky is shocked when longtime parishioner Anna May Branson leaves Sunday service only to be murdered in her home moments later. Investigators...	\N
170	1	F9	Dom lives a quiet life with Letty and his son, but Cipher enlists Dom's younger brother, Jakob, to complete a mission and get revenge on Dom and the team, so they must all work together to...	G
171	5	FBI	The team faces the demands of a kidnapper who abducted the director of a Brooklyn migrant center and his wife; Maggie uses Jessica to learn more about the ins and outs of motherhood.	TV-14
172	5	On Patrol: Live	Clayton County officers search for an armed carjacking suspect; Toledo officers race to shots fired.	TV-14
173	5	Engineering Catastrophes	A catastrophic fire at a fertilizer plant threatens city-wide devastation in Winston-Salem, N. C.; experts use the latest science to investigate and uncover an outdated, wooden storage...	TV-PG
174	5	Secret Nazi Ruins	A secret construction project in Eastern Germany, which began as the Nazis conducted their rise to power and boasts an elaborate network of underground tunnels and bunkers, is investigated by...	TV-PG
175	5	Mayday: Air Disaster	When three aircraft fall out of the sky, investigators are left to gather the pieces amid the severe conditions of the far North.	TV-14
176	5	Law & Order	Newly-discovered evidence will point the investigating detectives in the direction of a fascist youth gathering after the brutal beating and murder of a high school girl, but the teenagers are...	TV-14
177	5	The Andy Griffith Show	Barney's discovery of a bank satchel containing an ample allowance of stolen currency leads to his ambitious attempt to lure the furtive robbers to justice by using their own illicit loot,...	\N
178	5	Cocaine Bear	A plane filled with cocaine begins to have trouble midair and suddenly crashes into a Georgia forest, but then a curious big, black bear finds the transported stash and ingests a large amount...	R
179	5	NCIS: Los Angeles	Detective Deeks has his morning routine disrupted when he is shot during a convenience store robbery, leaving the NCIS team to investigate into the fact whether the assailants' intentions were...	TV-14
180	5	The Office	Michael finds himself unsettled after he hears some troubling rumors about Dunder Mifflin, and he forces the office into a day of strange diversions that leads everyone to wonder if he has...	TV-14
181	1	Fiddler on the Roof	A proud, Jewish peasant and milkman living in a Ukrainian ghetto before the Russian Revolution struggles to preserve his family's Jewish heritage amidst poverty, prejudiced attitudes of...	PG
182	5	The Loud House	When Lily Loud starts misbehaving at home, Mom and Dad think her new preschool friends might be the cause; when Rusty is wrongfully suspended, the Action News Team leaps into action to clear...	TV-Y7
183	3	The Loud House	Lincoln convinces his teacher, Mr. Bolhofner, to join the Doo-Dads in order to get a better seat in class; after Lincoln tries to help Lynn get over a heckler at her soccer game, the Louds...	TV-Y7
184	5	Save My Skin	The large tumours on Jennifer's scalp have left her with bald patches. Plus, Adam hopes to get a diagnosis for more than 60 lumps covering his body.	\N
185	5	MILF Manor	A double date leads to awkward situations for two contestants; Barby and Jacob grow closer; one contestant has her secret exposed.	TV-14
186	5	Cold Case	Lilly brings up a family's suppressed and depressing memories when she reopens a case from 1982 in which an infant was found dead due to the possible actions of the older brother, who...	TV-14
187	5	Paranormal Caught on Camera	The owner of the Plough Inn in Doncaster, England, named Jane Bushell, claims to have captured footage of a destructive spirit wreaking havoc; footage of a Sasquatch-like creature and...	TV-PG
188	5	Impractical Jokers: Inside Jokes	One Joker is an avid photographer; there are some words that the guys never want to hear before a punishment; one Joker is never afraid to strip down.	TV-14
189	5	Seinfeld	Jerry and Elaine try to discover the origin of a mysterious and pungent odor left in Jerry's car, which they trace back to a valet from a local restaurant; George becomes interesting in Susan...	TV-PG
190	5	How I Met Your Mother	After a night of wild partying, Ted wakes up to find he has a sprained ankle, and that a burnt jacket, a pineapple and a girl are in his bed, so he requests the help of his friends to piece...	TV-PG
191	5	Nick Cannon Presents: Wild 'N Out	WNBA star Skylar Diggins competes; rapper Vic Mensa performs.	TV-14
192	5	QAnon: The Search for Q	After the failed January 6 insurrection, Marley Clements and Bayan Joonam investigate a new war waged in local school boards and elections.	TV-14
193	5	S.W.A.T.	Hondo and Lina are undercover to infiltrate and retrieve a cruise ship that has been attacked by drug smugglers who threaten to kill passengers; Street finds the competition in the SWAT...	TV-14
194	5	The Braxtons	The family gathers to share their feelings and memories during grief counseling to cope with the loss of Traci but when emotions run high and a family member suddenly leaves the session, Miss...	TV-14
195	5	Storm of Suspicion	As Palm Beach, Fla., prepares for the incoming impact of Hurricane Andrew, a mother and her daughter are suddenly murdered in their home so the police team up with a forensic meteorologist to...	\N
196	5	When Weather Changed History	A historical look is taken into the dramatic events surrounding the destruction of a hurricane that struck Galveston, Texas, in 1900, as experts believe it was more powerful than disasters...	\N
197	5	House of the Dragon	As the search for Aemond and Vhagar continues, Daemon attempts to control the spiraling situation in King's Landing.	TV-MA
198	5	Life, Larry and the Pursuit of Unhappiness	As the search for Aemond and Vhagar continues, Daemon attempts to control the spiraling situation in King's Landing.	TV-MA
199	5	Warfare	President and Mrs. Obama want to honor America's 250th anniversary and celebrate the history of the nation on the occasion, but then Larry David calls.	\N
200	1	Deadpool 2	After Wade Wilson, also known as Deadpool, suffers from a personal tragedy, he decides to form his own team of super-powered mutants, in order to save a young and angry mutant who is targeted...	R
201	1	House of the Dragon	\N	\N
202	1	Mickey 17	A down-on-his-luck man enrolls in a program that will secure his way out of Earth, but when a mishap on one of his missions suddenly occurs, it results in multiple versions of himself forcing...	\N
203	5	The Leftovers	Kevin makes a strong-willed effort to rid himself of Patti and her influence on an unexpected field of battle, where a shocking, heart-rending choice is the definitive action that stands...	TV-MA
204	1	Eddington	The worry and uncertainty of the pandemic have left the residents of a small New Mexico town uneasy, so when a family is suddenly found murdered in their home, it pits neighbor against...	R
205	1	The Long Walk	Every year, one hundred young boys are chosen to participate in an annual competition that offers the ultimate grand prize to the victor, but failure to comply with the rules will be...	R
206	5	Godzilla vs. Gigan	When an evil alien plot to conquer the world using Gigan and King Ghidrah surfaces, Godzilla and Anguirus must join forces to save humanity from destruction.	PG
207	1	Son of Godzilla	Scientists on a remote island encounter deadly giant mantises and a recently hatched baby Godzilla.	\N
208	1	Pirate Radio	During the 1960s, a youth becomes involved with a pirate radio station that broadcasts rock 'n' roll without a license to the U.K. from a cramped boat anchored in international waters, but...	R
209	1	Heretic	Two young women are excited to discuss the importance of faith with a man who invites them into his home, but they become fearful for their lives when they learn that the man has suddenly...	R
210	1	Body At Brighton Rock	When a park employee takes on a tough assignment to prove herself, she finds a potential crime scene while lost in the backcountry, where she must overcome her worst fears and spend the night...	R
211	1	Happy Death Day	A young female college student continually relives the day of her murder, including both the ordinary circumstances and its terrifying conclusion, dying a different way each time, until she is...	PG-13
212	1	Final Destination 5	After having a terrible premonition about a suspension bridge collapsing, a young man and his coworkers manage to survive the accident, but they must now find a way to cheat death, which has...	R
213	1	Shot Caller	A fresh-out-of-prison, ruthless gangster must accept the demands of his gang to coordinate a major crime with a vicious rival organization on the streets of southern California, navigating a...	R
214	1	Y2K	On the last night of 1999, two high school juniors crash a New Year's Eve party, only to find themselves fighting for their lives when the terror of Y2K becomes a reality and all machines rise...	TV-14
215	5	Faster	\N	\N
216	1	Scream 4	Sidney Prescott has done her best to put the atrocities of her youth behind her and feels equipped to return to her hometown to promote a new book, but she brings with her a familiar enemy who...	R
217	1	Daniela Forever	After the death of his beloved girlfriend, a grieving man is given a new type of drug that invokes lucid dreams in an effort to help him overcome his pain, but mistreatment of the drug...	R
218	1	Not Without Hope	Four friends face disaster when their boat capsizes in the Gulf of Mexico. Battling massive waves, sharks, dehydration and hypothermia, they cling to hope as the Coast Guard launch a daring...	R
219	1	Undisputed	A top-ranked heavyweight professional boxing champion is convicted of rape and sent to prison where he decides to fight in a match for the prison boxing title after a violent confrontation...	R
220	1	THE RESURGENCE: DeMarcus Cousins	A top-ranked heavyweight professional boxing champion is convicted of rape and sent to prison where he decides to fight in a match for the prison boxing title after a violent confrontation...	R
221	1	The Comeback Trail	Two movie producers become indebted to the mob, so they attempt to save themselves by setting up an aging actor for an insurance scam.	R
222	1	Pootie Tang	Two movie producers become indebted to the mob, so they attempt to save themselves by setting up an aging actor for an insurance scam.	R
223	5	Star Trek: Insurrection	Captain Picard and the crew of the Enterprise must leap into action when the Federation risks the destruction of a planet belonging to a peaceful race of people in an attempt to gain access to...	G
224	1	Orange County	An over-achieving California teen is rejected from a prestigious college when his guidance counselor accidentally provides the incorrect transcript for his application, so he teams up with his...	PG-13
225	1	Queen Bees	An over-achieving California teen is rejected from a prestigious college when his guidance counselor accidentally provides the incorrect transcript for his application, so he teams up with his...	PG-13
226	5	Everybody Wants Some!!	A hotshot high school pitcher becomes a member of a successful Texas college team in the fall of 1980, where he and his rambunctious and frequently irresponsible team mates will be required to...	R
227	1	Good Burger	The longstanding prosperity of a humble hometown burger joint comes under considerable threat from competition, when a massively funded fast-food franchise opens up their business across the...	PG
228	1	Failure to Launch	The fed-up parents of a 35-year-old slacker who still lives at home hire a romantic interventionist to get him to move out, but the plan to build his self-esteem by conning him into falling in...	PG-13
229	5	Virtuosity	\N	\N
230	1	South Park: Bigger, Longer & Uncut	Scandalized when their children start repeating the bad words they hear in a crass Canadian movie, American parents declare war on Canada, setting in motion a plot that will allow Satan to...	R
231	1	Day of the Fight	Scandalized when their children start repeating the bad words they hear in a crass Canadian movie, American parents declare war on Canada, setting in motion a plot that will allow Satan to...	R
232	5	Would You Rather	\N	\N
233	1	All the World is Sleeping	\N	\N
234	1	Scream 3	As a production company starts work on Stab 3, Sydney's now peaceful life is interrupted by yet another knife-wielding masked killer as she and her friends begin to realize that they are...	R
235	1	Lara Croft: Tomb Raider	A beautiful British archaeologist follows in her late father's footsteps as she travels around the globe to stop a secret society from gaining possession of a magical relic with the power to...	TV-14
236	1	Raiders of the Lost Ark	In 1936, archaeologist, adventurer and college professor Indiana Jones races against Nazi forces and a brilliant rival to find the lost Ark of the Covenant, a relic with vast and dangerous...	G
237	1	Terms of Endearment	A woman searches for love and happiness while her demanding mother questions her choices, but a medical crisis forces them to put their longstanding differences aside to come through for each...	PG
238	1	Black Lotus	A former special forces agent attempting to move on from his former life discovers that his friend's young daughter has been kidnapped and decides to do everything he can to find her and bring...	\N
239	1	The Beldham	A struggling new mother fights a generations-old presence lurking within her family's home, threatening her safety, her sanity and the life of her infant child.	\N
240	5	Bait	After his dying cellmate gives him a mysterious clue about the location of a $42-million depository of stolen gold, a petty New York thief is unwittingly used by the FBI to draw out the...	R
241	1	The Man in the White Van	A rebellious young girl in a small little town in Florida raises concerns about an enigmatic white van, which many see as an attention-seeking ploy, but she becomes fearful for her life when...	PG-13
242	1	Van Helsing	A supernatural hunter with no memory of his true identity is sent on a mission to help the last member of a family dedicated in ending the rampage of Count Dracula and his experiments before...	PG-13
243	1	Escape From Pretoria	During the tumultuous apartheid days of South African, two white South Africans get imprisoned for working on behalf of the African National Congress, but the pair soon becomes determined to...	PG-13
244	1	Rememory	A pioneer of science creates a device that has the ability to extract, record and play a person's memories, but following his death, the invention is stolen from his widow by a man who...	PG-13
245	5	High School	After a soon-to-be valedictorian named Henry Burke smokes marijuana for the first time, it coincides with a new, mandatory drug test for all students at his school, so he and his friends set...	R
246	1	Hi-Life	A man who desperately wants to become an actor puts all his options on the table in order to get out of the shadow of a dangerous bookie to whom he is indebted, and he decides to go to any...	R
247	1	The Queen of Spain	A glamorous 1950s actress returns from Hollywood to Madrid to star in a musical about Spain's Queen Isabella, encountering old friends and associates from her days in an acting troupe, while...	\N
248	1	Crave	After the Prime Minister of Serbia is assassinated, an ex-British serviceman turned mercenary and an elite special ops team is sent to Europe to rescue a kidnapped U.S. ambassador before the...	R
249	1	Fairhaven	When a man in his mid-thirties returns to his hometown and reunites with his childhood friends during a funeral, they start to reevaluate their lives and try to make sense of what mistakes...	\N
250	1	Dreams	Experience the Gathering of the Juggalos through the eyes of first-timers. The infamous music festival plays host to thousands of "Juggalos" as they party like nobody's watching.	\N
251	1	My Dog the Champion	A city teenager is forced to live on her grandfather's farm while her mother works overseas, and when she discovers that her family needs money to save the farm, she trains for an upcoming dog...	G
252	1	Beautiful Wave	Spending the summer at the home of her grandmother in Santa Cruz, Calif., a young woman from New York realizes her great passion for the sport of surfing and also discovers a decades-old...	PG-13
253	1	The Strangers: Chapter 3	Maya faces the masked killers one last time in a brutal, full-circle reckoning of survival and revenge.	R
254	1	The Hard Hit	An Interpol agent is on a mission of vengeance after he is tasked with hunting down the head of an international crime syndicate in Las Vegas, the criminal organization takes its revenge on...	\N
255	5	Girl in Progress	As single mom Grace juggles work, bills, and her affair with a married doctor, her daughter, Ansiedad, plots a shortcut to adulthood after finding inspiration in the coming-of-age stories...	PG-13
256	1	Joey and Ella	A worldly teenager stumbles upon a baby kangaroo that has been separated from its mother and inadvertently forced into being part of a jewelry heist, but several people try to stop her from...	G
257	1	What's Cooking?	In Los Angeles' Fairfax district, tensions quickly rise to the surface as four ethnically diverse families struggle with differing relationship issues as they gather together in order to...	PG-13
258	1	The Woman in Green	Scotland Yard turns to Sherlock Holmes for assistance when they begin to receive the severed fingers of four women who are murdered; his investigation uncovers a bizarre trail that includes...	PG
259	1	Transit	A family attempts to have a pleasant camping experience in order to strengthen their bond, but their vacation quickly turns into a brutal fight for survival, when a gang of bank robbers begins...	R
260	5	The Grudge 2	A woman travels from the United States to Tokyo to bring her sister home and crosses the path of the dark spirit that was released when the building where it resided was burned, giving it the...	PG-13
261	1	The Day	In a post-apocalyptic world ravaged by war, a group of five survivors with dwindling food and ammunition suddenly find themselves forced into a fight for their lives inside a deserted...	R
262	1	High Ground	Heartbroken after the death of his family and searching for vengeance, a young man seeks the assistance of a former soldier and they slowly earn each other's confidence and trust as they hunt...	TV-14
263	1	The Hunting Party	A successful journalist is reunited with his now-discredited former boss as they set out on a mission to locate and interview an infamous war criminal in hiding, but the situation takes a...	R
264	1	Marshall	In conservative Connecticut, future Supreme Court Justice Thurgood Marshall fights racism and Anti-Semitism as he defends a black chauffeur who has been charged with the attempted murder and...	G
265	5	Macbeth	Consumed with ambition and greed after receiving a prophecy from three witches, a Scottish lord murders the king of Scotland and takes the throne for himself, but he soon becomes paranoid as a...	R
266	1	Big Eyes	In the 1950s and 1960s, a divorced mother finds solace in painting, and after courtship leads to marriage, it also leads to her new husband taking credit for her art when the works gain...	G
267	1	Shotgun	When a sheriff goes up against an outlaw, the situation is complicated by the fact that they both love the same woman.	\N
268	1	Don Ricardo Returns	A Spanish nobleman journeys to California to accept his inheritance and discovers that his cousin has claimed the inheritance by declaring him legally dead, so he enlists the aid of local...	\N
269	5	The Westies	Sweeney strikes a deal with Castellano: rob a Colombian disco and Flanagan walks free; Bridget seeks counsel about Cahill, while Keenan investigates the killing of a cop in Boston.	\N
270	1	A House on the Bayou	A couple and their daughter travel to rural Louisiana for an idyllic getaway at a remote mansion, where an uninvited group of worryingly courteous neighbors arrive and sends the family down a...	TV-MA
271	1	There's Something Wrong with the Children	A couple and their daughter travel to rural Louisiana for an idyllic getaway at a remote mansion, where an uninvited group of worryingly courteous neighbors arrive and sends the family down a...	TV-MA
272	1	The Legend of Bagger Vance	A mystical caddy helps a one-time golfing great regain his "authentic swing" so he can compete in an exhibition put on by his former girlfriend who needs to save her family's golf course from...	PG-13
273	1	Boo! A Madea Halloween	When she must keep an eye on a group of mischievous, misbehaving teenagers on Halloween night, the tough, no-nonsense Madea is forced to go to great lengths in order to go up against killers,...	PG-13
274	1	LaRoy, Texas	A husband in a failing marriage unexpectedly decides to take a job as a hired hitman, but when he is suddenly pressed by the town's sheriff, he attempts to persuade everyone that he is not the...	\N
275	1	The Keep	A company of Nazi soldiers who have been charged with keeping watch over a Romanian citadel are forced to turn to a knowledgeable Jewish man and his daughter for help after an evil force is...	R
276	1	Audrey Rose	An unsuspecting couple lives in fear after a shadowy stalker approaches them with persistent claims that their 11-year-old daughter is secretly a reincarnation of his own child that passed...	PG
\.


--
-- TOC entry 4944 (class 2606 OID 18097)
-- Name: broadcast_schedules broadcast_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broadcast_schedules
    ADD CONSTRAINT broadcast_schedules_pkey PRIMARY KEY (schedule_id);


--
-- TOC entry 4939 (class 2606 OID 18074)
-- Name: episodes episodes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_pkey PRIMARY KEY (episode_id);


--
-- TOC entry 4933 (class 2606 OID 18045)
-- Name: genres genres_genre_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_genre_name_key UNIQUE (genre_name);


--
-- TOC entry 4935 (class 2606 OID 18043)
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- TOC entry 4937 (class 2606 OID 18052)
-- Name: program_genres program_genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_genres
    ADD CONSTRAINT program_genres_pkey PRIMARY KEY (program_id, genre_id);


--
-- TOC entry 4920 (class 2606 OID 18005)
-- Name: program_types program_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_types
    ADD CONSTRAINT program_types_pkey PRIMARY KEY (program_type_id);


--
-- TOC entry 4922 (class 2606 OID 18007)
-- Name: program_types program_types_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_types
    ADD CONSTRAINT program_types_type_name_key UNIQUE (type_name);


--
-- TOC entry 4924 (class 2606 OID 18017)
-- Name: tv_channels tv_channels_call_sign_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tv_channels
    ADD CONSTRAINT tv_channels_call_sign_key UNIQUE (call_sign);


--
-- TOC entry 4926 (class 2606 OID 18015)
-- Name: tv_channels tv_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tv_channels
    ADD CONSTRAINT tv_channels_pkey PRIMARY KEY (channel_id);


--
-- TOC entry 4929 (class 2606 OID 18028)
-- Name: tv_programs tv_programs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tv_programs
    ADD CONSTRAINT tv_programs_pkey PRIMARY KEY (program_id);


--
-- TOC entry 4942 (class 2606 OID 18076)
-- Name: episodes uq_episode_program_season_episode; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT uq_episode_program_season_episode UNIQUE (program_id, season_number, episode_number);


--
-- TOC entry 4931 (class 2606 OID 18030)
-- Name: tv_programs uq_program_type_title; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tv_programs
    ADD CONSTRAINT uq_program_type_title UNIQUE (program_type_id, title);


--
-- TOC entry 4948 (class 2606 OID 18099)
-- Name: broadcast_schedules uq_schedule_channel_date_start; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broadcast_schedules
    ADD CONSTRAINT uq_schedule_channel_date_start UNIQUE (channel_id, broadcast_date, start_time);


--
-- TOC entry 4940 (class 1259 OID 18116)
-- Name: idx_episodes_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_episodes_program ON public.episodes USING btree (program_id);


--
-- TOC entry 4945 (class 1259 OID 18118)
-- Name: idx_schedules_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_schedules_date ON public.broadcast_schedules USING btree (broadcast_date);


--
-- TOC entry 4946 (class 1259 OID 18117)
-- Name: idx_schedules_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_schedules_program ON public.broadcast_schedules USING btree (program_id);


--
-- TOC entry 4927 (class 1259 OID 18115)
-- Name: idx_tv_programs_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tv_programs_type ON public.tv_programs USING btree (program_type_id);


--
-- TOC entry 4956 (class 2620 OID 18120)
-- Name: broadcast_schedules trg_prevent_schedule_overlap; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevent_schedule_overlap BEFORE INSERT OR UPDATE OF channel_id, broadcast_date, start_time, end_time ON public.broadcast_schedules FOR EACH ROW EXECUTE FUNCTION public.prevent_schedule_overlap();


--
-- TOC entry 4957 (class 2620 OID 18119)
-- Name: broadcast_schedules trg_validate_schedule_episode; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validate_schedule_episode BEFORE INSERT OR UPDATE OF program_id, episode_id ON public.broadcast_schedules FOR EACH ROW EXECUTE FUNCTION public.validate_schedule_episode();


--
-- TOC entry 4952 (class 2606 OID 18077)
-- Name: episodes fk_episode_program; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT fk_episode_program FOREIGN KEY (program_id) REFERENCES public.tv_programs(program_id) ON DELETE CASCADE;


--
-- TOC entry 4950 (class 2606 OID 18058)
-- Name: program_genres fk_program_genres_genre; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_genres
    ADD CONSTRAINT fk_program_genres_genre FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id) ON DELETE CASCADE;


--
-- TOC entry 4951 (class 2606 OID 18053)
-- Name: program_genres fk_program_genres_program; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_genres
    ADD CONSTRAINT fk_program_genres_program FOREIGN KEY (program_id) REFERENCES public.tv_programs(program_id) ON DELETE CASCADE;


--
-- TOC entry 4949 (class 2606 OID 18031)
-- Name: tv_programs fk_program_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tv_programs
    ADD CONSTRAINT fk_program_type FOREIGN KEY (program_type_id) REFERENCES public.program_types(program_type_id);


--
-- TOC entry 4953 (class 2606 OID 18100)
-- Name: broadcast_schedules fk_schedule_channel; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broadcast_schedules
    ADD CONSTRAINT fk_schedule_channel FOREIGN KEY (channel_id) REFERENCES public.tv_channels(channel_id);


--
-- TOC entry 4954 (class 2606 OID 18110)
-- Name: broadcast_schedules fk_schedule_episode; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broadcast_schedules
    ADD CONSTRAINT fk_schedule_episode FOREIGN KEY (episode_id) REFERENCES public.episodes(episode_id);


--
-- TOC entry 4955 (class 2606 OID 18105)
-- Name: broadcast_schedules fk_schedule_program; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broadcast_schedules
    ADD CONSTRAINT fk_schedule_program FOREIGN KEY (program_id) REFERENCES public.tv_programs(program_id);


-- Completed on 2026-07-23 15:02:07

--
-- PostgreSQL database dump complete
--

\unrestrict ZXAKb1xqV1lfguFi8eJYR1KDJu0swGklEWEXyEytbYX6LPUQ9nVEsy6eFB2Q399

