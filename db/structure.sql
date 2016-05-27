--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: fill_descriptives_vector_for_venue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_descriptives_vector_for_venue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

      begin               
        new.descriptives_vector :=
          setweight(to_tsvector('pg_catalog.english', coalesce(new.categories_string, '')), 'A') ||
          setweight(to_tsvector('pg_catalog.english', coalesce(new.descriptives_string, '')), 'B')||
          setweight(to_tsvector('pg_catalog.english', coalesce(new.trending_tags_string, '')), 'B');

        return new;
      end
      $$;


--
-- Name: fill_meta_data_vector_for_venue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_meta_data_vector_for_venue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      declare
        venue_meta_data record;
        

      begin
        
        
        select string_agg(meta, ' ') as meta into venue_meta_data from meta_data where venue_id = new.id and (NOW() - created_at) <= INTERVAL '1 DAY';

        new.meta_data_vector :=
          to_tsvector('pg_catalog.english', coalesce(venue_meta_data.meta, ''));


        return new;
      end
      $$;


--
-- Name: fill_meta_data_vector_for_venue_comments(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_meta_data_vector_for_venue_comments() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      declare
        venue_comment_meta_data record;
        

      begin
        
        
        select string_agg(meta, ' ') as meta into venue_comment_meta_data from meta_data where venue_comment_id = new.id and (NOW() - created_at) <= INTERVAL '1 DAY';

        new.meta_data_vector :=
          to_tsvector('pg_catalog.english', coalesce(venue_comment_meta_data.meta, ''));


        return new;
      end
      $$;


--
-- Name: fill_metaphone_name_vector_expd_for_venue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_metaphone_name_vector_expd_for_venue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        
      begin

        new.metaphone_name_vector_expd :=
          setweight(to_tsvector('pg_catalog.english', pg_search_dmetaphone(coalesce(regexp_replace(new.name, '[^a-zA-Zd :]+', '', 'g'), ''))), 'A') ||
          setweight(to_tsvector('pg_catalog.english', pg_search_dmetaphone(coalesce(regexp_replace(new.name, '[^a-zA-Zd :]+', '', 'g')||new.city, ''))), 'A');



        return new;
      end
      $$;


--
-- Name: fill_metaphone_name_vector_for_venue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_metaphone_name_vector_for_venue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        
      begin

        new.metaphone_name_vector :=
          to_tsvector('pg_catalog.english', pg_search_dmetaphone(coalesce(new.name, '')));



        return new;
      end
      $$;


--
-- Name: fill_search_vector_for_feed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_search_vector_for_feed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      declare
      	feed_venue_data record;
        
      begin

      	select string_agg(description, ' ') as added_note into feed_venue_data from feed_venues where feed_id = new.id;

        new.search_vector :=
          setweight(to_tsvector('pg_catalog.english', coalesce(new.name, '')), 'A') ||
          setweight(to_tsvector('pg_catalog.english', coalesce(new.description, '')), 'B') ||
          setweight(to_tsvector('pg_catalog.english', coalesce(feed_venue_data.added_note, '')), 'C');

        return new;
      end
      $$;


--
-- Name: fill_ts_categories_vector_for_feed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_categories_vector_for_feed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	      declare
	      feed_category_entries record;	      

	      begin 
	      	SELECT string_agg(name, ' ') AS names INTO feed_category_entries FROM list_categories WHERE id IN (SELECT list_category_id FROM list_category_entries WHERE feed_id = new.id);

	        new.ts_categories_vector :=
	        	to_tsvector('pg_catalog.english', coalesce(feed_category_entries.names, ''));

	        return new;
	      end
	      $$;


--
-- Name: fill_ts_description_vector_for_feed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_description_vector_for_feed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

	 	begin         
        new.ts_description_vector :=
        	to_tsvector('pg_catalog.english', coalesce(new.description, ''));

        return new;
      end
      $$;


--
-- Name: fill_ts_meta_vector_for_feed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_meta_vector_for_feed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      declare
      	feed_venue_data record;
      	assgined_category record;
        
      begin

      	select string_agg(description, ' ') as added_note into feed_venue_data from feed_venues where feed_id = new.id;

        new.ts_meta_vector :=
          to_tsvector('pg_catalog.english', coalesce(feed_venue_data.added_note, ''));


        return new;
      end
      $$;


--
-- Name: fill_ts_name_city_vector_for_venue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_name_city_vector_for_venue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

      begin
         
        new.ts_name_city_vector :=
        	to_tsvector('pg_catalog.english', coalesce(new.name||new.city, ''));

        return new;
      end
      $$;


--
-- Name: fill_ts_name_country_vector_for_venue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_name_country_vector_for_venue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

      begin
         
        new.ts_name_country_vector :=
        	to_tsvector('pg_catalog.english', coalesce(new.name||new.country, ''));

        return new;
      end
      $$;


--
-- Name: fill_ts_name_vector_expd_for_venue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_name_vector_expd_for_venue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      declare
        venue_meta_data record;
        

      begin
        
        
        new.ts_name_vector_expd :=
        	setweight(to_tsvector('pg_catalog.english', coalesce(regexp_replace(new.name, '[^a-zA-Zd :]+', '', 'g'), '')), 'A') ||
        	setweight(to_tsvector('pg_catalog.english', coalesce(regexp_replace(new.name, '[^a-zA-Zd :]+', '', 'g')||new.city, '')), 'A');

        return new;
      end
      $$;


--
-- Name: fill_ts_name_vector_for_feed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_name_vector_for_feed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

      begin 
        new.ts_name_vector :=
        	to_tsvector('pg_catalog.english', coalesce(new.name, ''));

        return new;
      end
      $$;


--
-- Name: fill_ts_name_vector_for_venue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_name_vector_for_venue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      declare
        venue_meta_data record;
        

      begin
        
        
        new.ts_name_vector :=
        	to_tsvector('pg_catalog.english', coalesce(new.name, ''));

        return new;
      end
      $$;


--
-- Name: fill_ts_venue_descriptives_vector_for_feed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fill_ts_venue_descriptives_vector_for_feed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	      declare
	      feed_venue_descriptives record;	      

	      begin 
	      	SELECT string_agg(description, ' ') AS descriptives INTO feed_venue_descriptives FROM feed_venues WHERE feed_id = new.id;

	        new.ts_venue_descriptives_vector :=
	        	to_tsvector('pg_catalog.english', coalesce(feed_venue_descriptives.descriptives, ''));

	        return new;
	      end
	      $$;


--
-- Name: pg_search_dmetaphone(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION pg_search_dmetaphone(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E'\\s+')))), ' ')
$_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activities (
    id integer NOT NULL,
    feed_id integer,
    activity_type character varying(255),
    feed_venue_id integer,
    feed_user_id integer,
    feed_recommendation_id integer,
    adjusted_sort_position bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    num_likes integer DEFAULT 0,
    num_comments integer DEFAULT 0,
    user_id integer,
    venue_id integer,
    latest_comment_time timestamp without time zone,
    num_participants integer DEFAULT 0,
    venue_comment_id integer,
    message text,
    num_lists integer DEFAULT 1,
    feed_name character varying(255),
    feed_color character varying(255),
    feed_creator_id integer,
    user_name character varying(255),
    user_phone character varying(255),
    venue_instagram_location_id integer,
    venue_latitude double precision,
    venue_longitude double precision,
    venue_name character varying(255),
    venue_address character varying(255),
    venue_city character varying(255),
    venue_state character varying(255),
    venue_country character varying(255),
    venue_added_note text,
    venue_comment_created_at timestamp without time zone,
    venue_comment_media_type character varying(255),
    venue_comment_content_origin character varying(255),
    venue_comment_thirdparty_username character varying(255),
    image_url_1 character varying(255),
    image_url_2 character varying(255),
    image_url_3 character varying(255),
    video_url_1 character varying(255),
    video_url_2 character varying(255),
    video_url_3 character varying(255),
    tag_1 character varying(255),
    tag_2 character varying(255),
    tag_3 character varying(255),
    tag_4 character varying(255),
    tag_5 character varying(255),
    twitter_id bigint,
    tweet_text text,
    tweet_created_at timestamp without time zone,
    tweet_author_name character varying(255),
    tweet_author_id character varying(255),
    tweet_author_avatar_url character varying(255),
    tweet_handle character varying(255),
    media_type character varying(255),
    user_facebook_id bigint,
    user_facebook_name character varying(255),
    lytit_tweet_id integer,
    venue_comment_details json DEFAULT '{}'::json NOT NULL,
    event json DEFAULT '{}'::json NOT NULL,
    venue_details json DEFAULT '{}'::json NOT NULL,
    feed_details json DEFAULT '{}'::json NOT NULL,
    user_details json DEFAULT '{}'::json NOT NULL,
    feed_user_details json DEFAULT '{}'::json NOT NULL,
    feed_venue_details json DEFAULT '{}'::json NOT NULL,
    topic_details json DEFAULT '{}'::json NOT NULL
);


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activities_id_seq OWNED BY activities.id;


--
-- Name: activity_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activity_comments (
    id integer NOT NULL,
    activity_id integer,
    user_id integer,
    comment text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_details json DEFAULT '{}'::json NOT NULL
);


--
-- Name: activity_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_comments_id_seq OWNED BY activity_comments.id;


--
-- Name: activity_feeds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activity_feeds (
    id integer NOT NULL,
    activity_id integer,
    feed_id integer
);


--
-- Name: activity_feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_feeds_id_seq OWNED BY activity_feeds.id;


--
-- Name: announcement_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE announcement_users (
    id integer NOT NULL,
    user_id integer,
    announcement_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: announcement_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE announcement_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcement_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE announcement_users_id_seq OWNED BY announcement_users.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE announcements (
    id integer NOT NULL,
    news character varying(255),
    send_to_all boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    title character varying(255)
);


--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE announcements_id_seq OWNED BY announcements.id;


--
-- Name: cluster_trackers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cluster_trackers (
    id integer NOT NULL,
    latitude double precision,
    longitude double precision,
    zoom_level double precision,
    num_venues integer,
    last_twitter_pull_time timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cluster_trackers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cluster_trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cluster_trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cluster_trackers_id_seq OWNED BY cluster_trackers.id;


--
-- Name: comment_views; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comment_views (
    id integer NOT NULL,
    venue_comment_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: comment_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comment_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comment_views_id_seq OWNED BY comment_views.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    queue character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: event_announcements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE event_announcements (
    id integer NOT NULL,
    event_id integer,
    comment text,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: event_announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_announcements_id_seq OWNED BY event_announcements.id;


--
-- Name: event_organizers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE event_organizers (
    id integer NOT NULL,
    event_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: event_organizers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_organizers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_organizers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_organizers_id_seq OWNED BY event_organizers.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events (
    id integer NOT NULL,
    name character varying(255),
    description text,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    venue_id integer,
    low_image_url character varying(255),
    medium_image_url character varying(255),
    regular_image_url character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    category character varying(255),
    source character varying(255),
    source_url text,
    eventbrite_id bigint,
    cover_image_url text
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: exported_data_csvs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE exported_data_csvs (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    csv_file_file_name character varying(255),
    csv_file_content_type character varying(255),
    csv_file_file_size integer,
    csv_file_updated_at timestamp without time zone,
    type character varying(255),
    job_id integer
);


--
-- Name: exported_data_csvs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE exported_data_csvs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exported_data_csvs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE exported_data_csvs_id_seq OWNED BY exported_data_csvs.id;


--
-- Name: favorite_venues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE favorite_venues (
    id integer NOT NULL,
    venue_id integer,
    user_id integer,
    interest_score double precision DEFAULT 1.0,
    num_new_moments integer,
    latest_venue_check_time timestamp without time zone,
    venue_name character varying(255),
    venue_details json DEFAULT '{}'::json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    latest_check_time timestamp without time zone
);


--
-- Name: favorite_venues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE favorite_venues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favorite_venues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE favorite_venues_id_seq OWNED BY favorite_venues.id;


--
-- Name: feed_invitations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_invitations (
    id integer NOT NULL,
    inviter_id integer,
    invitee_id integer,
    feed_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: feed_invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feed_invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_invitations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feed_invitations_id_seq OWNED BY feed_invitations.id;


--
-- Name: feed_join_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_join_requests (
    id integer NOT NULL,
    user_id integer,
    feed_id integer,
    granted boolean,
    note character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: feed_join_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feed_join_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_join_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feed_join_requests_id_seq OWNED BY feed_join_requests.id;


--
-- Name: feed_recommendations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_recommendations (
    id integer NOT NULL,
    feed_id integer,
    category character varying(255),
    active boolean DEFAULT true,
    spotlyt boolean DEFAULT false,
    image_url character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: feed_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feed_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feed_recommendations_id_seq OWNED BY feed_recommendations.id;


--
-- Name: feed_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_users (
    id integer NOT NULL,
    user_id integer,
    feed_id integer,
    creator boolean DEFAULT false,
    last_visit timestamp without time zone,
    is_subscribed boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    interest_score double precision DEFAULT 0.0
);


--
-- Name: feed_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feed_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feed_users_id_seq OWNED BY feed_users.id;


--
-- Name: feed_venues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_venues (
    id integer NOT NULL,
    feed_id integer,
    venue_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    num_upvotes integer DEFAULT 0,
    num_comments integer DEFAULT 0,
    upvote_user_ids json DEFAULT '[]'::json NOT NULL,
    venue_details json DEFAULT '{}'::json NOT NULL,
    user_details json DEFAULT '{}'::json NOT NULL,
    activity_id integer,
    num_venues integer,
    num_users integer,
    score_primer integer DEFAULT 0,
    lonlat_geometry geometry(Point),
    lonlat_geography geography(Point,4326),
    feed_details json DEFAULT '{}'::json
);


--
-- Name: feed_venues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feed_venues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_venues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feed_venues_id_seq OWNED BY feed_venues.id;


--
-- Name: feeds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feeds (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    num_venues integer DEFAULT 0,
    feed_color character varying(255),
    user_id integer,
    open boolean DEFAULT true,
    num_users integer DEFAULT 1,
    latest_content_time timestamp without time zone,
    description text,
    code character varying(255),
    num_moments integer DEFAULT 0,
    central_mass_latitude double precision,
    central_mass_longitude double precision,
    search_vector tsvector,
    latest_update_time timestamp without time zone,
    ts_name_vector tsvector,
    ts_description_vector tsvector,
    ts_categories_vector tsvector,
    ts_meta_vector tsvector,
    preview_image_url character varying(255),
    cover_image_url character varying(255),
    is_private boolean DEFAULT false,
    list_category_id integer,
    venue_attributes json DEFAULT '{"descriptives":{},"venue_categories":{}}'::json NOT NULL,
    venue_attributes_string character varying,
    central_mass_lonlat_geometry geometry(Point),
    central_mass_lonlat_geography geography(Point,4326),
    venue_ids json DEFAULT '[]'::json NOT NULL,
    in_spotlyt boolean DEFAULT false,
    ts_venue_descriptives_vector tsvector
);


--
-- Name: feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feeds_id_seq OWNED BY feeds.id;


--
-- Name: flagged_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flagged_comments (
    id integer NOT NULL,
    venue_comment_id integer,
    user_id integer,
    message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: flagged_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flagged_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flagged_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flagged_comments_id_seq OWNED BY flagged_comments.id;


--
-- Name: instagram_auth_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE instagram_auth_tokens (
    id integer NOT NULL,
    token character varying(255),
    num_used integer DEFAULT 0,
    is_valid boolean DEFAULT true,
    instagram_user_id integer,
    instagram_username character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: instagram_auth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE instagram_auth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: instagram_auth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE instagram_auth_tokens_id_seq OWNED BY instagram_auth_tokens.id;


--
-- Name: instagram_location_id_lookups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE instagram_location_id_lookups (
    id integer NOT NULL,
    venue_id integer,
    instagram_location_id bigint
);


--
-- Name: instagram_location_id_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE instagram_location_id_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: instagram_location_id_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE instagram_location_id_lookups_id_seq OWNED BY instagram_location_id_lookups.id;


--
-- Name: instagram_vortexes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE instagram_vortexes (
    id integer NOT NULL,
    latitude double precision,
    longitude double precision,
    last_instagram_pull_time timestamp without time zone,
    city character varying(255),
    pull_radius double precision,
    active boolean,
    details character varying(255),
    vortex_group_que integer,
    movement_direction integer,
    turn_cycle integer,
    last_user_ping timestamp without time zone,
    country character varying(255),
    vortex_group integer,
    time_zone_offset double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    time_zone character varying(255)
);


--
-- Name: instagram_vortexes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE instagram_vortexes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: instagram_vortexes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE instagram_vortexes_id_seq OWNED BY instagram_vortexes.id;


--
-- Name: likes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE likes (
    id integer NOT NULL,
    liked_id integer,
    liker_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    activity_id integer
);


--
-- Name: likes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE likes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE likes_id_seq OWNED BY likes.id;


--
-- Name: list_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE list_categories (
    id integer NOT NULL,
    name character varying(255),
    tags json DEFAULT '{}'::json NOT NULL,
    num_lists integer DEFAULT 0,
    thumbnail_image_url text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: list_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE list_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: list_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE list_categories_id_seq OWNED BY list_categories.id;


--
-- Name: list_category_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE list_category_entries (
    id integer NOT NULL,
    feed_id integer,
    list_category_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: list_category_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE list_category_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: list_category_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE list_category_entries_id_seq OWNED BY list_category_entries.id;


--
-- Name: lyt_spheres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lyt_spheres (
    id integer NOT NULL,
    venue_id integer,
    sphere character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: lyt_spheres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lyt_spheres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lyt_spheres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lyt_spheres_id_seq OWNED BY lyt_spheres.id;


--
-- Name: lytit_bars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lytit_bars (
    id integer NOT NULL,
    "position" double precision
);


--
-- Name: lytit_bars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lytit_bars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lytit_bars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lytit_bars_id_seq OWNED BY lytit_bars.id;


--
-- Name: lytit_constants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lytit_constants (
    id integer NOT NULL,
    constant_name character varying(255),
    constant_value double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    big_value bigint
);


--
-- Name: lytit_constants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lytit_constants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lytit_constants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lytit_constants_id_seq OWNED BY lytit_constants.id;


--
-- Name: lytit_votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lytit_votes (
    id integer NOT NULL,
    value integer,
    venue_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    venue_rating double precision,
    prime double precision,
    raw_value double precision,
    rating_after double precision,
    time_wrapper timestamp without time zone
);


--
-- Name: lytit_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lytit_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lytit_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lytit_votes_id_seq OWNED BY lytit_votes.id;


--
-- Name: menu_section_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE menu_section_items (
    id integer NOT NULL,
    name character varying(255),
    price double precision,
    menu_section_id integer,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "position" integer
);


--
-- Name: menu_section_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE menu_section_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_section_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE menu_section_items_id_seq OWNED BY menu_section_items.id;


--
-- Name: menu_sections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE menu_sections (
    id integer NOT NULL,
    name character varying(255),
    venue_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "position" integer
);


--
-- Name: menu_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE menu_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE menu_sections_id_seq OWNED BY menu_sections.id;


--
-- Name: meta_data; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE meta_data (
    id integer NOT NULL,
    meta character varying(255),
    venue_id integer,
    venue_comment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    clean_meta character varying(255),
    relevance_score double precision DEFAULT 0.0
);


--
-- Name: meta_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meta_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meta_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meta_data_id_seq OWNED BY meta_data.id;


--
-- Name: moment_request_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE moment_request_users (
    id integer NOT NULL,
    user_id integer,
    moment_request_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: moment_request_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE moment_request_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moment_request_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE moment_request_users_id_seq OWNED BY moment_request_users.id;


--
-- Name: moment_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE moment_requests (
    id integer NOT NULL,
    venue_id integer,
    user_id integer,
    latitude double precision,
    longitude double precision,
    num_requesters integer DEFAULT 0,
    expiration timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: moment_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE moment_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moment_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE moment_requests_id_seq OWNED BY moment_requests.id;


--
-- Name: pg_search_documents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pg_search_documents (
    id integer NOT NULL,
    content text,
    searchable_id integer,
    searchable_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pg_search_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pg_search_documents_id_seq OWNED BY pg_search_documents.id;


--
-- Name: post_passes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE post_passes (
    id integer NOT NULL,
    user_id integer,
    venue_comment_id integer,
    passed_on boolean,
    reported boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: post_passes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE post_passes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_passes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE post_passes_id_seq OWNED BY post_passes.id;


--
-- Name: reported_objects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reported_objects (
    id integer NOT NULL,
    report_type character varying(255),
    reporter_id integer,
    user_id integer,
    venue_comment_id integer,
    feed_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    activity_comment_id integer
);


--
-- Name: reported_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reported_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reported_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reported_objects_id_seq OWNED BY reported_objects.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: support_issues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE support_issues (
    id integer NOT NULL,
    user_id integer,
    latest_message_time timestamp without time zone,
    latest_open_time timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: support_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE support_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: support_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE support_issues_id_seq OWNED BY support_issues.id;


--
-- Name: support_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE support_messages (
    id integer NOT NULL,
    message text,
    support_issue_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: support_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE support_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: support_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE support_messages_id_seq OWNED BY support_messages.id;


--
-- Name: surrounding_pull_trackers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE surrounding_pull_trackers (
    id integer NOT NULL,
    user_id integer,
    latest_pull_time timestamp without time zone,
    latitude double precision,
    longitude double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: surrounding_pull_trackers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE surrounding_pull_trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: surrounding_pull_trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE surrounding_pull_trackers_id_seq OWNED BY surrounding_pull_trackers.id;


--
-- Name: tweets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tweets (
    id integer NOT NULL,
    twitter_id bigint,
    tweet_text character varying(255),
    author_id character varying(255),
    author_name character varying(255),
    author_avatar character varying(255),
    "timestamp" timestamp without time zone,
    venue_id integer,
    from_cluster boolean,
    associated_zoomlevel double precision,
    cluster_min_venue_id integer,
    latitude double precision,
    longitude double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    popularity_score double precision DEFAULT 0.0,
    handle character varying(255),
    image_url_1 character varying(255),
    image_url_2 character varying(255),
    image_url_3 character varying(255)
);


--
-- Name: tweets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tweets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tweets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tweets_id_seq OWNED BY tweets.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    email character varying(255) NOT NULL,
    encrypted_password character varying(128) NOT NULL,
    confirmation_token character varying(128),
    remember_token character varying(128) NOT NULL,
    name character varying(255),
    authentication_token character varying(255),
    push_token text,
    role_id integer,
    username_private boolean DEFAULT false,
    gcm_token character varying(255),
    version character varying(255) DEFAULT '1.0.0'::character varying,
    email_confirmed boolean DEFAULT false,
    registered boolean DEFAULT false,
    vendor_id character varying(255),
    asked_instagram_permission boolean DEFAULT false,
    country_code character varying(255),
    phone_number character varying(255),
    num_likes integer DEFAULT 0,
    active boolean DEFAULT true,
    num_lists integer DEFAULT 0,
    facebook_id bigint,
    facebook_name character varying(255),
    num_bolts integer DEFAULT 0,
    interests json DEFAULT '{}'::json NOT NULL,
    profile_description text,
    profile_image_url text,
    latitude double precision,
    longitude double precision,
    lonlat_geometry geometry(Point),
    lonlat_geography geography(Point,4326),
    violations json DEFAULT '{}'::json NOT NULL,
    is_verified boolean DEFAULT false,
    num_daily_moments integer
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: vendor_id_trackers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vendor_id_trackers (
    id integer NOT NULL,
    used_vendor_id character varying(255)
);


--
-- Name: vendor_id_trackers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE vendor_id_trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor_id_trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE vendor_id_trackers_id_seq OWNED BY vendor_id_trackers.id;


--
-- Name: venue_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE venue_comments (
    id integer NOT NULL,
    comment character varying(255),
    media_type character varying(255),
    image_url_1 character varying(255),
    user_id integer,
    venue_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    num_enlytened integer DEFAULT 0,
    adj_views double precision DEFAULT 0.0,
    offset_created_at character varying(255),
    content_origin character varying(255),
    time_wrapper timestamp without time zone,
    instagram_id character varying(255),
    thirdparty_username character varying(255),
    image_url_2 character varying(255),
    image_url_3 character varying(255),
    video_url_1 character varying(255),
    video_url_2 character varying(255),
    video_url_3 character varying(255),
    instagram_user_id bigint,
    meta_data_vector tsvector,
    media_dimensions character varying(255),
    geo_views json DEFAULT '{}'::json NOT NULL,
    adjusted_sort_position integer DEFAULT 0,
    tweet json DEFAULT '{}'::json NOT NULL,
    event json DEFAULT '{}'::json NOT NULL,
    lytit_post json DEFAULT '{}'::json NOT NULL,
    instagram json DEFAULT '{}'::json NOT NULL,
    user_details json DEFAULT '{}'::json NOT NULL,
    venue_details json DEFAULT '{}'::json NOT NULL,
    entry_type character varying(255),
    visible boolean DEFAULT true,
    active boolean DEFAULT true,
    evaluater_user_ids json DEFAULT '{}'::json NOT NULL
);


--
-- Name: venue_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE venue_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venue_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE venue_comments_id_seq OWNED BY venue_comments.id;


--
-- Name: venue_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE venue_messages (
    id integer NOT NULL,
    message character varying(255),
    venue_id integer,
    "position" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: venue_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE venue_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venue_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE venue_messages_id_seq OWNED BY venue_messages.id;


--
-- Name: venue_page_views; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE venue_page_views (
    id integer NOT NULL,
    user_id integer,
    venue_id integer,
    venue_lyt_sphere character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    consider boolean DEFAULT true
);


--
-- Name: venue_page_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE venue_page_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venue_page_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE venue_page_views_id_seq OWNED BY venue_page_views.id;


--
-- Name: venue_question_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE venue_question_comments (
    id integer NOT NULL,
    venue_question_id integer,
    comment text,
    from_location boolean,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: venue_question_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE venue_question_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venue_question_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE venue_question_comments_id_seq OWNED BY venue_question_comments.id;


--
-- Name: venue_ratings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE venue_ratings (
    id integer NOT NULL,
    user_id integer,
    venue_id integer,
    rating double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: venue_ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE venue_ratings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venue_ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE venue_ratings_id_seq OWNED BY venue_ratings.id;


--
-- Name: venues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE venues (
    id integer NOT NULL,
    name character varying(255),
    rating double precision,
    phone_number character varying(255),
    address text,
    city character varying(255),
    state character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    latitude double precision,
    longitude double precision,
    country character varying(255),
    postal_code character varying(255),
    formatted_address text,
    fetched_at timestamp without time zone,
    r_up_votes double precision DEFAULT 1.0,
    r_down_votes double precision DEFAULT 1.0,
    color_rating double precision DEFAULT (-1.0),
    time_zone character varying(255),
    latest_posted_comment_time timestamp without time zone,
    popularity_rank double precision DEFAULT 0.0,
    page_views double precision DEFAULT 0,
    instagram_location_id bigint,
    last_instagram_pull_time timestamp without time zone,
    verified boolean DEFAULT true,
    latest_page_view_time timestamp without time zone,
    time_zone_offset double precision,
    trend_position integer,
    last_instagram_post character varying(255),
    latest_rating_update_time timestamp without time zone,
    last_twitter_pull_time timestamp without time zone,
    meta_data_vector tsvector,
    event_id integer,
    venue_comment_id integer,
    metaphone_name_vector tsvector,
    open_hours json DEFAULT '{}'::json NOT NULL,
    instagram_vortex_id integer,
    foursquare_id character varying(255),
    ts_name_vector tsvector,
    ts_name_city_vector tsvector,
    ts_name_country_vector tsvector,
    popular_hours json DEFAULT '{}'::json NOT NULL,
    hist_rating_avgs json DEFAULT '{"hour_1":{"rating":0,"count":0},"hour_2":{"rating":0,"count":0},"hour_3":{"rating":0,"count":0},"hour_4":{"rating":0,"count":0},"hour_5":{"rating":0,"count":0},"hour_6":{"rating":0,"count":0},"hour_7":{"rating":0,"count":0},"hour_8":{"rating":0,"count":0},"hour_9":{"rating":0,"count":0},"hour_10":{"rating":0,"count":0},"hour_11":{"rating":0,"count":0},"hour_12":{"rating":0,"count":0},"hour_13":{"rating":0,"count":0},"hour_14":{"rating":0,"count":0},"hour_15":{"rating":0,"count":0},"hour_16":{"rating":0,"count":0},"hour_17":{"rating":0,"count":0},"hour_18":{"rating":0,"count":0},"hour_19":{"rating":0,"count":0},"hour_20":{"rating":0,"count":0},"hour_21":{"rating":0,"count":0},"hour_22":{"rating":0,"count":0},"hour_23":{"rating":0,"count":0},"hour_0":{"rating":0,"count":0}}'::json NOT NULL,
    venue_comment_details json DEFAULT '{}'::json NOT NULL,
    page_offset integer DEFAULT 0,
    latest_tweet json DEFAULT '{}'::json NOT NULL,
    ts_name_vector_expd tsvector,
    metaphone_name_vector_expd tsvector,
    categories json DEFAULT '{}'::json NOT NULL,
    categories_string text DEFAULT ''::text,
    trending_tags json DEFAULT '{}'::json NOT NULL,
    trending_tags_string text DEFAULT ''::text,
    descriptives json DEFAULT '{}'::json NOT NULL,
    descriptives_string text DEFAULT ''::text,
    descriptives_vector tsvector,
    event_details json DEFAULT '{}'::json NOT NULL,
    last_tweet_id bigint,
    last_instagram_id character varying(255),
    moment_request_details json DEFAULT '{}'::json NOT NULL,
    lonlat_geometry geometry(Point),
    lonlat_geography geography(Point,4326),
    latest_comment_type_times json DEFAULT '{"lytit_post":"2016-05-09T22:50:27.053-04:00","instagram":"2016-05-09T22:50:27.053-04:00","tweet":"2016-05-09T22:50:27.053-04:00","event":"2016-05-09T22:50:27.053-04:00"}'::json NOT NULL,
    is_proposed boolean DEFAULT false,
    linked_lists json DEFAULT '{}'::json,
    linked_list_ids integer[] DEFAULT '{}'::integer[]
);


--
-- Name: venues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE venues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE venues_id_seq OWNED BY venues.id;


--
-- Name: vortex_paths; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vortex_paths (
    id integer NOT NULL,
    instagram_vortex_id integer,
    origin_lat double precision,
    origin_long double precision,
    span double precision,
    increment_distance double precision
);


--
-- Name: vortex_paths_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE vortex_paths_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vortex_paths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE vortex_paths_id_seq OWNED BY vortex_paths.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities ALTER COLUMN id SET DEFAULT nextval('activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_comments ALTER COLUMN id SET DEFAULT nextval('activity_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_feeds ALTER COLUMN id SET DEFAULT nextval('activity_feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY announcement_users ALTER COLUMN id SET DEFAULT nextval('announcement_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY announcements ALTER COLUMN id SET DEFAULT nextval('announcements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cluster_trackers ALTER COLUMN id SET DEFAULT nextval('cluster_trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comment_views ALTER COLUMN id SET DEFAULT nextval('comment_views_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_announcements ALTER COLUMN id SET DEFAULT nextval('event_announcements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_organizers ALTER COLUMN id SET DEFAULT nextval('event_organizers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY exported_data_csvs ALTER COLUMN id SET DEFAULT nextval('exported_data_csvs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorite_venues ALTER COLUMN id SET DEFAULT nextval('favorite_venues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_invitations ALTER COLUMN id SET DEFAULT nextval('feed_invitations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_join_requests ALTER COLUMN id SET DEFAULT nextval('feed_join_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_recommendations ALTER COLUMN id SET DEFAULT nextval('feed_recommendations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_users ALTER COLUMN id SET DEFAULT nextval('feed_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_venues ALTER COLUMN id SET DEFAULT nextval('feed_venues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feeds ALTER COLUMN id SET DEFAULT nextval('feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flagged_comments ALTER COLUMN id SET DEFAULT nextval('flagged_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY instagram_auth_tokens ALTER COLUMN id SET DEFAULT nextval('instagram_auth_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY instagram_location_id_lookups ALTER COLUMN id SET DEFAULT nextval('instagram_location_id_lookups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY instagram_vortexes ALTER COLUMN id SET DEFAULT nextval('instagram_vortexes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY likes ALTER COLUMN id SET DEFAULT nextval('likes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY list_categories ALTER COLUMN id SET DEFAULT nextval('list_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY list_category_entries ALTER COLUMN id SET DEFAULT nextval('list_category_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lyt_spheres ALTER COLUMN id SET DEFAULT nextval('lyt_spheres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lytit_bars ALTER COLUMN id SET DEFAULT nextval('lytit_bars_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lytit_constants ALTER COLUMN id SET DEFAULT nextval('lytit_constants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lytit_votes ALTER COLUMN id SET DEFAULT nextval('lytit_votes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY menu_section_items ALTER COLUMN id SET DEFAULT nextval('menu_section_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY menu_sections ALTER COLUMN id SET DEFAULT nextval('menu_sections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data ALTER COLUMN id SET DEFAULT nextval('meta_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY moment_request_users ALTER COLUMN id SET DEFAULT nextval('moment_request_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY moment_requests ALTER COLUMN id SET DEFAULT nextval('moment_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pg_search_documents ALTER COLUMN id SET DEFAULT nextval('pg_search_documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_passes ALTER COLUMN id SET DEFAULT nextval('post_passes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reported_objects ALTER COLUMN id SET DEFAULT nextval('reported_objects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY support_issues ALTER COLUMN id SET DEFAULT nextval('support_issues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY support_messages ALTER COLUMN id SET DEFAULT nextval('support_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY surrounding_pull_trackers ALTER COLUMN id SET DEFAULT nextval('surrounding_pull_trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tweets ALTER COLUMN id SET DEFAULT nextval('tweets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY vendor_id_trackers ALTER COLUMN id SET DEFAULT nextval('vendor_id_trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY venue_comments ALTER COLUMN id SET DEFAULT nextval('venue_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY venue_messages ALTER COLUMN id SET DEFAULT nextval('venue_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY venue_page_views ALTER COLUMN id SET DEFAULT nextval('venue_page_views_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY venue_question_comments ALTER COLUMN id SET DEFAULT nextval('venue_question_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY venue_ratings ALTER COLUMN id SET DEFAULT nextval('venue_ratings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY venues ALTER COLUMN id SET DEFAULT nextval('venues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY vortex_paths ALTER COLUMN id SET DEFAULT nextval('vortex_paths_id_seq'::regclass);


--
-- Name: activity_feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_feeds
    ADD CONSTRAINT activity_feeds_pkey PRIMARY KEY (id);


--
-- Name: announcement_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY announcement_users
    ADD CONSTRAINT announcement_users_pkey PRIMARY KEY (id);


--
-- Name: announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: cluster_trackers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cluster_trackers
    ADD CONSTRAINT cluster_trackers_pkey PRIMARY KEY (id);


--
-- Name: comment_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comment_views
    ADD CONSTRAINT comment_views_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: event_announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_announcements
    ADD CONSTRAINT event_announcements_pkey PRIMARY KEY (id);


--
-- Name: event_organizers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_organizers
    ADD CONSTRAINT event_organizers_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: exported_data_csvs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY exported_data_csvs
    ADD CONSTRAINT exported_data_csvs_pkey PRIMARY KEY (id);


--
-- Name: favorite_venues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY favorite_venues
    ADD CONSTRAINT favorite_venues_pkey PRIMARY KEY (id);


--
-- Name: feed_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activities
    ADD CONSTRAINT feed_activities_pkey PRIMARY KEY (id);


--
-- Name: feed_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_invitations
    ADD CONSTRAINT feed_invitations_pkey PRIMARY KEY (id);


--
-- Name: feed_join_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_join_requests
    ADD CONSTRAINT feed_join_requests_pkey PRIMARY KEY (id);


--
-- Name: feed_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_recommendations
    ADD CONSTRAINT feed_recommendations_pkey PRIMARY KEY (id);


--
-- Name: feed_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_users
    ADD CONSTRAINT feed_users_pkey PRIMARY KEY (id);


--
-- Name: feed_venues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_venues
    ADD CONSTRAINT feed_venues_pkey PRIMARY KEY (id);


--
-- Name: feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (id);


--
-- Name: flagged_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flagged_comments
    ADD CONSTRAINT flagged_comments_pkey PRIMARY KEY (id);


--
-- Name: instagram_auth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY instagram_auth_tokens
    ADD CONSTRAINT instagram_auth_tokens_pkey PRIMARY KEY (id);


--
-- Name: instagram_location_id_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY instagram_location_id_lookups
    ADD CONSTRAINT instagram_location_id_lookups_pkey PRIMARY KEY (id);


--
-- Name: instagram_vortexes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY instagram_vortexes
    ADD CONSTRAINT instagram_vortexes_pkey PRIMARY KEY (id);


--
-- Name: likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: list_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY list_categories
    ADD CONSTRAINT list_categories_pkey PRIMARY KEY (id);


--
-- Name: list_category_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY list_category_entries
    ADD CONSTRAINT list_category_entries_pkey PRIMARY KEY (id);


--
-- Name: lyt_spheres_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lyt_spheres
    ADD CONSTRAINT lyt_spheres_pkey PRIMARY KEY (id);


--
-- Name: lytit_bars_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lytit_bars
    ADD CONSTRAINT lytit_bars_pkey PRIMARY KEY (id);


--
-- Name: lytit_constants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lytit_constants
    ADD CONSTRAINT lytit_constants_pkey PRIMARY KEY (id);


--
-- Name: lytit_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lytit_votes
    ADD CONSTRAINT lytit_votes_pkey PRIMARY KEY (id);


--
-- Name: menu_section_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY menu_section_items
    ADD CONSTRAINT menu_section_items_pkey PRIMARY KEY (id);


--
-- Name: menu_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY menu_sections
    ADD CONSTRAINT menu_sections_pkey PRIMARY KEY (id);


--
-- Name: meta_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY meta_data
    ADD CONSTRAINT meta_data_pkey PRIMARY KEY (id);


--
-- Name: moment_request_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY moment_request_users
    ADD CONSTRAINT moment_request_users_pkey PRIMARY KEY (id);


--
-- Name: moment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY moment_requests
    ADD CONSTRAINT moment_requests_pkey PRIMARY KEY (id);


--
-- Name: pg_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pg_search_documents
    ADD CONSTRAINT pg_search_documents_pkey PRIMARY KEY (id);


--
-- Name: post_passes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY post_passes
    ADD CONSTRAINT post_passes_pkey PRIMARY KEY (id);


--
-- Name: reported_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reported_objects
    ADD CONSTRAINT reported_objects_pkey PRIMARY KEY (id);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: support_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY support_issues
    ADD CONSTRAINT support_issues_pkey PRIMARY KEY (id);


--
-- Name: support_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY support_messages
    ADD CONSTRAINT support_messages_pkey PRIMARY KEY (id);


--
-- Name: surrounding_pull_trackers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY surrounding_pull_trackers
    ADD CONSTRAINT surrounding_pull_trackers_pkey PRIMARY KEY (id);


--
-- Name: tweets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tweets
    ADD CONSTRAINT tweets_pkey PRIMARY KEY (id);


--
-- Name: user_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_comments
    ADD CONSTRAINT user_comments_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vendor_id_trackers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vendor_id_trackers
    ADD CONSTRAINT vendor_id_trackers_pkey PRIMARY KEY (id);


--
-- Name: venue_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY venue_comments
    ADD CONSTRAINT venue_comments_pkey PRIMARY KEY (id);


--
-- Name: venue_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY venue_messages
    ADD CONSTRAINT venue_messages_pkey PRIMARY KEY (id);


--
-- Name: venue_page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY venue_page_views
    ADD CONSTRAINT venue_page_views_pkey PRIMARY KEY (id);


--
-- Name: venue_question_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY venue_question_comments
    ADD CONSTRAINT venue_question_comments_pkey PRIMARY KEY (id);


--
-- Name: venue_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY venue_ratings
    ADD CONSTRAINT venue_ratings_pkey PRIMARY KEY (id);


--
-- Name: venues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY venues
    ADD CONSTRAINT venues_pkey PRIMARY KEY (id);


--
-- Name: vortex_paths_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vortex_paths
    ADD CONSTRAINT vortex_paths_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_activities_on_adjusted_sort_position; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_adjusted_sort_position ON activities USING btree (adjusted_sort_position);


--
-- Name: index_activities_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_created_at ON activities USING btree (created_at);


--
-- Name: index_activities_on_feed_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activities_on_feed_id ON activities USING btree (feed_id);


--
-- Name: index_activity_comments_on_activity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_comments_on_activity_id ON activity_comments USING btree (activity_id);


--
-- Name: index_activity_comments_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_comments_on_user_id ON activity_comments USING btree (user_id);


--
-- Name: index_activity_feeds_on_activity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_feeds_on_activity_id ON activity_feeds USING btree (activity_id);


--
-- Name: index_activity_feeds_on_feed_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_feeds_on_feed_id ON activity_feeds USING btree (feed_id);


--
-- Name: index_announcement_users_on_announcement_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_announcement_users_on_announcement_id ON announcement_users USING btree (announcement_id);


--
-- Name: index_announcement_users_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_announcement_users_on_user_id ON announcement_users USING btree (user_id);


--
-- Name: index_cluster_trackers_on_latitude; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_cluster_trackers_on_latitude ON cluster_trackers USING btree (latitude);


--
-- Name: index_cluster_trackers_on_longitude; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_cluster_trackers_on_longitude ON cluster_trackers USING btree (longitude);


--
-- Name: index_cluster_trackers_on_zoom_level; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_cluster_trackers_on_zoom_level ON cluster_trackers USING btree (zoom_level);


--
-- Name: index_comment_views_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comment_views_on_user_id ON comment_views USING btree (user_id);


--
-- Name: index_comment_views_on_venue_comment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comment_views_on_venue_comment_id ON comment_views USING btree (venue_comment_id);


--
-- Name: index_event_announcements_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_announcements_on_event_id ON event_announcements USING btree (event_id);


--
-- Name: index_event_announcements_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_announcements_on_user_id ON event_announcements USING btree (user_id);


--
-- Name: index_event_organizers_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_organizers_on_event_id ON event_organizers USING btree (event_id);


--
-- Name: index_event_organizers_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_organizers_on_user_id ON event_organizers USING btree (user_id);


--
-- Name: index_events_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_events_on_venue_id ON events USING btree (venue_id);


--
-- Name: index_favorite_venues_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_favorite_venues_on_user_id ON favorite_venues USING btree (user_id);


--
-- Name: index_feed_invitations_on_invitee_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_invitations_on_invitee_id ON feed_invitations USING btree (invitee_id);


--
-- Name: index_feed_invitations_on_inviter_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_invitations_on_inviter_id ON feed_invitations USING btree (inviter_id);


--
-- Name: index_feed_recommendations_on_category; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_recommendations_on_category ON feed_recommendations USING btree (category);


--
-- Name: index_feed_recommendations_on_feed_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_recommendations_on_feed_id ON feed_recommendations USING btree (feed_id);


--
-- Name: index_feed_users_on_feed_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_users_on_feed_id ON feed_users USING btree (feed_id);


--
-- Name: index_feed_users_on_feed_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_feed_users_on_feed_id_and_user_id ON feed_users USING btree (feed_id, user_id);


--
-- Name: index_feed_users_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_users_on_user_id ON feed_users USING btree (user_id);


--
-- Name: index_feed_venues_on_feed_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_venues_on_feed_id ON feed_venues USING btree (feed_id);


--
-- Name: index_feed_venues_on_feed_id_and_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_feed_venues_on_feed_id_and_venue_id ON feed_venues USING btree (feed_id, venue_id);


--
-- Name: index_feed_venues_on_lonlat_geography; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_venues_on_lonlat_geography ON feed_venues USING gist (lonlat_geography);


--
-- Name: index_feed_venues_on_lonlat_geometry; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_venues_on_lonlat_geometry ON feed_venues USING gist (lonlat_geometry);


--
-- Name: index_feed_venues_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_venues_on_venue_id ON feed_venues USING btree (venue_id);


--
-- Name: index_feeds_on_central_mass_lonlat_geography; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_central_mass_lonlat_geography ON feeds USING gist (central_mass_lonlat_geography);


--
-- Name: index_feeds_on_central_mass_lonlat_geometry; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_central_mass_lonlat_geometry ON feeds USING gist (central_mass_lonlat_geometry);


--
-- Name: index_feeds_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_name ON feeds USING btree (name);


--
-- Name: index_feeds_on_name_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_feeds_on_name_and_user_id ON feeds USING btree (name, user_id);


--
-- Name: index_feeds_on_search_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_search_vector ON feeds USING gin (search_vector);


--
-- Name: index_feeds_on_ts_categories_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_ts_categories_vector ON feeds USING gin (ts_categories_vector);


--
-- Name: index_feeds_on_ts_description_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_ts_description_vector ON feeds USING gin (ts_description_vector);


--
-- Name: index_feeds_on_ts_meta_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_ts_meta_vector ON feeds USING gin (ts_meta_vector);


--
-- Name: index_feeds_on_ts_name_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_ts_name_vector ON feeds USING gin (ts_name_vector);


--
-- Name: index_feeds_on_ts_venue_descriptives_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_ts_venue_descriptives_vector ON feeds USING gin (ts_venue_descriptives_vector);


--
-- Name: index_instagram_auth_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_instagram_auth_tokens_on_user_id ON instagram_auth_tokens USING btree (user_id);


--
-- Name: index_instagram_location_id_lookups_on_instagram_location_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_instagram_location_id_lookups_on_instagram_location_id ON instagram_location_id_lookups USING btree (instagram_location_id);


--
-- Name: index_instagram_location_id_lookups_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_instagram_location_id_lookups_on_venue_id ON instagram_location_id_lookups USING btree (venue_id);


--
-- Name: index_likes_on_liked_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_likes_on_liked_id ON likes USING btree (liked_id);


--
-- Name: index_likes_on_liker_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_likes_on_liker_id ON likes USING btree (liker_id);


--
-- Name: index_list_category_entries_on_feed_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_list_category_entries_on_feed_id ON list_category_entries USING btree (feed_id);


--
-- Name: index_list_category_entries_on_list_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_list_category_entries_on_list_category_id ON list_category_entries USING btree (list_category_id);


--
-- Name: index_lyt_spheres_on_sphere; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_lyt_spheres_on_sphere ON lyt_spheres USING btree (sphere);


--
-- Name: index_lyt_spheres_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_lyt_spheres_on_venue_id ON lyt_spheres USING btree (venue_id);


--
-- Name: index_lytit_votes_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_lytit_votes_on_venue_id ON lytit_votes USING btree (venue_id);


--
-- Name: index_menu_section_items_on_menu_section_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_menu_section_items_on_menu_section_id ON menu_section_items USING btree (menu_section_id);


--
-- Name: index_menu_sections_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_menu_sections_on_venue_id ON menu_sections USING btree (venue_id);


--
-- Name: index_meta_data_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_meta_data_on_created_at ON meta_data USING btree (created_at);


--
-- Name: index_meta_data_on_meta; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_meta_data_on_meta ON meta_data USING btree (meta);


--
-- Name: index_meta_data_on_meta_and_venue_comment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_meta_data_on_meta_and_venue_comment_id ON meta_data USING btree (meta, venue_comment_id);


--
-- Name: index_meta_data_on_relevance_score; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_meta_data_on_relevance_score ON meta_data USING btree (relevance_score);


--
-- Name: index_meta_data_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_meta_data_on_venue_id ON meta_data USING btree (venue_id);


--
-- Name: index_moment_requests_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_moment_requests_on_user_id ON moment_requests USING btree (user_id);


--
-- Name: index_moment_requests_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_moment_requests_on_venue_id ON moment_requests USING btree (venue_id);


--
-- Name: index_on_venues_location; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_on_venues_location ON venues USING gist (st_geographyfromtext((((('SRID=4326;POINT('::text || longitude) || ' '::text) || latitude) || ')'::text)));


--
-- Name: index_pg_search_documents_on_searchable_id_and_searchable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pg_search_documents_on_searchable_id_and_searchable_type ON pg_search_documents USING btree (searchable_id, searchable_type);


--
-- Name: index_post_passes_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_post_passes_on_created_at ON post_passes USING btree (created_at);


--
-- Name: index_post_passes_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_post_passes_on_user_id ON post_passes USING btree (user_id);


--
-- Name: index_support_issues_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_support_issues_on_user_id ON support_issues USING btree (user_id);


--
-- Name: index_support_messages_on_support_issue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_support_messages_on_support_issue_id ON support_messages USING btree (support_issue_id);


--
-- Name: index_surrounding_pull_trackers_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_surrounding_pull_trackers_on_user_id ON surrounding_pull_trackers USING btree (user_id);


--
-- Name: index_tweets_on_latitude; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tweets_on_latitude ON tweets USING btree (latitude);


--
-- Name: index_tweets_on_longitude; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tweets_on_longitude ON tweets USING btree (longitude);


--
-- Name: index_tweets_on_popularity_score; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tweets_on_popularity_score ON tweets USING btree (popularity_score);


--
-- Name: index_tweets_on_timestamp; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tweets_on_timestamp ON tweets USING btree ("timestamp");


--
-- Name: index_tweets_on_twitter_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tweets_on_twitter_id ON tweets USING btree (twitter_id);


--
-- Name: index_tweets_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tweets_on_venue_id ON tweets USING btree (venue_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_lonlat_geography; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_lonlat_geography ON users USING gist (lonlat_geography);


--
-- Name: index_users_on_lonlat_geometry; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_lonlat_geometry ON users USING gist (lonlat_geometry);


--
-- Name: index_users_on_remember_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_remember_token ON users USING btree (remember_token);


--
-- Name: index_users_on_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_role_id ON users USING btree (role_id);


--
-- Name: index_venue_comments_on_id_and_instagram_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_venue_comments_on_id_and_instagram_id ON venue_comments USING btree (id, instagram_id);


--
-- Name: index_venue_comments_on_instagram_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_venue_comments_on_instagram_id ON venue_comments USING btree (instagram_id);


--
-- Name: index_venue_comments_on_meta_data_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_comments_on_meta_data_vector ON venue_comments USING gin (meta_data_vector);


--
-- Name: index_venue_comments_on_time_wrapper; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_comments_on_time_wrapper ON venue_comments USING btree (time_wrapper);


--
-- Name: index_venue_comments_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_comments_on_user_id ON venue_comments USING btree (user_id);


--
-- Name: index_venue_comments_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_comments_on_venue_id ON venue_comments USING btree (venue_id);


--
-- Name: index_venue_messages_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_messages_on_venue_id ON venue_messages USING btree (venue_id);


--
-- Name: index_venue_page_views_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_page_views_on_user_id ON venue_page_views USING btree (user_id);


--
-- Name: index_venue_page_views_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_page_views_on_venue_id ON venue_page_views USING btree (venue_id);


--
-- Name: index_venue_page_views_on_venue_lyt_sphere; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_page_views_on_venue_lyt_sphere ON venue_page_views USING btree (venue_lyt_sphere);


--
-- Name: index_venue_question_comments_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_question_comments_on_user_id ON venue_question_comments USING btree (user_id);


--
-- Name: index_venue_question_comments_on_venue_question_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_question_comments_on_venue_question_id ON venue_question_comments USING btree (venue_question_id);


--
-- Name: index_venue_ratings_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_ratings_on_user_id ON venue_ratings USING btree (user_id);


--
-- Name: index_venue_ratings_on_venue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venue_ratings_on_venue_id ON venue_ratings USING btree (venue_id);


--
-- Name: index_venues_on_color_rating; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_color_rating ON venues USING btree (color_rating);


--
-- Name: index_venues_on_descriptives_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_descriptives_vector ON venues USING gin (descriptives_vector);


--
-- Name: index_venues_on_instagram_location_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_instagram_location_id ON venues USING btree (instagram_location_id);


--
-- Name: index_venues_on_latitude; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_latitude ON venues USING btree (latitude);


--
-- Name: index_venues_on_linked_list_ids; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_linked_list_ids ON venues USING gin (linked_list_ids);


--
-- Name: index_venues_on_longitude; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_longitude ON venues USING btree (longitude);


--
-- Name: index_venues_on_lonlat_geography; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_lonlat_geography ON venues USING gist (lonlat_geography);


--
-- Name: index_venues_on_lonlat_geometry; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_lonlat_geometry ON venues USING gist (lonlat_geometry);


--
-- Name: index_venues_on_meta_data_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_meta_data_vector ON venues USING gin (meta_data_vector);


--
-- Name: index_venues_on_metaphone_name_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_metaphone_name_vector ON venues USING gin (metaphone_name_vector);


--
-- Name: index_venues_on_metaphone_name_vector_expd; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_metaphone_name_vector_expd ON venues USING gin (metaphone_name_vector_expd);


--
-- Name: index_venues_on_popularity_rank; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_popularity_rank ON venues USING btree (popularity_rank);


--
-- Name: index_venues_on_ts_name_city_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_ts_name_city_vector ON venues USING gin (ts_name_city_vector);


--
-- Name: index_venues_on_ts_name_country_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_ts_name_country_vector ON venues USING gin (ts_name_country_vector);


--
-- Name: index_venues_on_ts_name_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_ts_name_vector ON venues USING gin (ts_name_vector);


--
-- Name: index_venues_on_ts_name_vector_expd; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_venues_on_ts_name_vector_expd ON venues USING gin (ts_name_vector_expd);


--
-- Name: index_vortex_paths_on_instagram_vortex_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_vortex_paths_on_instagram_vortex_id ON vortex_paths USING btree (instagram_vortex_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: feed_search_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER feed_search_trigger BEFORE INSERT OR UPDATE ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_search_vector_for_feed();


--
-- Name: feeds_ts_categories_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER feeds_ts_categories_vector_trigger BEFORE INSERT OR UPDATE ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_categories_vector_for_feed();


--
-- Name: feeds_ts_description_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER feeds_ts_description_vector_trigger BEFORE INSERT OR UPDATE ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_description_vector_for_feed();


--
-- Name: feeds_ts_meta_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER feeds_ts_meta_vector_trigger BEFORE INSERT OR UPDATE ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_meta_vector_for_feed();


--
-- Name: feeds_ts_name_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER feeds_ts_name_vector_trigger BEFORE INSERT OR UPDATE ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_name_vector_for_feed();


--
-- Name: feeds_ts_venue_descriptives_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER feeds_ts_venue_descriptives_vector_trigger BEFORE INSERT OR UPDATE ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_venue_descriptives_vector_for_feed();


--
-- Name: venues_comment_meta_data_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_comment_meta_data_trigger BEFORE INSERT OR UPDATE ON venue_comments FOR EACH ROW EXECUTE PROCEDURE fill_meta_data_vector_for_venue_comments();


--
-- Name: venues_descriptives_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_descriptives_vector_trigger BEFORE INSERT OR UPDATE ON venues FOR EACH ROW EXECUTE PROCEDURE fill_descriptives_vector_for_venue();


--
-- Name: venues_meta_data_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_meta_data_trigger BEFORE INSERT OR UPDATE ON venues FOR EACH ROW EXECUTE PROCEDURE fill_meta_data_vector_for_venue();


--
-- Name: venues_metaphone_expd_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_metaphone_expd_trigger BEFORE INSERT OR UPDATE ON venues FOR EACH ROW EXECUTE PROCEDURE fill_metaphone_name_vector_expd_for_venue();


--
-- Name: venues_metaphone_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_metaphone_trigger BEFORE INSERT OR UPDATE ON venues FOR EACH ROW EXECUTE PROCEDURE fill_metaphone_name_vector_for_venue();


--
-- Name: venues_ts_name_city_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_ts_name_city_vector_trigger BEFORE INSERT OR UPDATE ON venues FOR EACH ROW EXECUTE PROCEDURE fill_ts_name_city_vector_for_venue();


--
-- Name: venues_ts_name_country_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_ts_name_country_vector_trigger BEFORE INSERT OR UPDATE ON venues FOR EACH ROW EXECUTE PROCEDURE fill_ts_name_country_vector_for_venue();


--
-- Name: venues_ts_name_vector_expd_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_ts_name_vector_expd_trigger BEFORE INSERT OR UPDATE ON venues FOR EACH ROW EXECUTE PROCEDURE fill_ts_name_vector_expd_for_venue();


--
-- Name: venues_ts_name_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER venues_ts_name_vector_trigger BEFORE INSERT OR UPDATE ON venues FOR EACH ROW EXECUTE PROCEDURE fill_ts_name_vector_for_venue();


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public, postgis;

INSERT INTO schema_migrations (version) VALUES ('20140324170210');

INSERT INTO schema_migrations (version) VALUES ('20140324171708');

INSERT INTO schema_migrations (version) VALUES ('20140328082338');

INSERT INTO schema_migrations (version) VALUES ('20140329182033');

INSERT INTO schema_migrations (version) VALUES ('20140407051719');

INSERT INTO schema_migrations (version) VALUES ('20140407064413');

INSERT INTO schema_migrations (version) VALUES ('20140415195519');

INSERT INTO schema_migrations (version) VALUES ('20140416134623');

INSERT INTO schema_migrations (version) VALUES ('20140423031013');

INSERT INTO schema_migrations (version) VALUES ('20140426180752');

INSERT INTO schema_migrations (version) VALUES ('20140428141224');

INSERT INTO schema_migrations (version) VALUES ('20140428162817');

INSERT INTO schema_migrations (version) VALUES ('20140428163614');

INSERT INTO schema_migrations (version) VALUES ('20140429075651');

INSERT INTO schema_migrations (version) VALUES ('20140501141745');

INSERT INTO schema_migrations (version) VALUES ('20140504015528');

INSERT INTO schema_migrations (version) VALUES ('20140506175210');

INSERT INTO schema_migrations (version) VALUES ('20140506190534');

INSERT INTO schema_migrations (version) VALUES ('20140507040126');

INSERT INTO schema_migrations (version) VALUES ('20140508135457');

INSERT INTO schema_migrations (version) VALUES ('20140508135816');

INSERT INTO schema_migrations (version) VALUES ('20140509165005');

INSERT INTO schema_migrations (version) VALUES ('20140512082010');

INSERT INTO schema_migrations (version) VALUES ('20140512085630');

INSERT INTO schema_migrations (version) VALUES ('20140513205548');

INSERT INTO schema_migrations (version) VALUES ('20140516071123');

INSERT INTO schema_migrations (version) VALUES ('20140520122711');

INSERT INTO schema_migrations (version) VALUES ('20140522183201');

INSERT INTO schema_migrations (version) VALUES ('20140526164902');

INSERT INTO schema_migrations (version) VALUES ('20140529044512');

INSERT INTO schema_migrations (version) VALUES ('20140529111758');

INSERT INTO schema_migrations (version) VALUES ('20140529163348');

INSERT INTO schema_migrations (version) VALUES ('20140529174202');

INSERT INTO schema_migrations (version) VALUES ('20140531124143');

INSERT INTO schema_migrations (version) VALUES ('20140531124231');

INSERT INTO schema_migrations (version) VALUES ('20140531180340');

INSERT INTO schema_migrations (version) VALUES ('20140604165036');

INSERT INTO schema_migrations (version) VALUES ('20140606181324');

INSERT INTO schema_migrations (version) VALUES ('20140606190129');

INSERT INTO schema_migrations (version) VALUES ('20140614080706');

INSERT INTO schema_migrations (version) VALUES ('20140615040422');

INSERT INTO schema_migrations (version) VALUES ('20140618024827');

INSERT INTO schema_migrations (version) VALUES ('20140625011900');

INSERT INTO schema_migrations (version) VALUES ('20140625202515');

INSERT INTO schema_migrations (version) VALUES ('20140626030420');

INSERT INTO schema_migrations (version) VALUES ('20140627124044');

INSERT INTO schema_migrations (version) VALUES ('20140627124300');

INSERT INTO schema_migrations (version) VALUES ('20140627200257');

INSERT INTO schema_migrations (version) VALUES ('20140628160040');

INSERT INTO schema_migrations (version) VALUES ('20140629063123');

INSERT INTO schema_migrations (version) VALUES ('20140629063150');

INSERT INTO schema_migrations (version) VALUES ('20140703155952');

INSERT INTO schema_migrations (version) VALUES ('20140707182705');

INSERT INTO schema_migrations (version) VALUES ('20140716143157');

INSERT INTO schema_migrations (version) VALUES ('20140721035100');

INSERT INTO schema_migrations (version) VALUES ('20140725014735');

INSERT INTO schema_migrations (version) VALUES ('20140728162656');

INSERT INTO schema_migrations (version) VALUES ('20140728162742');

INSERT INTO schema_migrations (version) VALUES ('20140728214527');

INSERT INTO schema_migrations (version) VALUES ('20141015000203');

INSERT INTO schema_migrations (version) VALUES ('20141015211904');

INSERT INTO schema_migrations (version) VALUES ('20141018210732');

INSERT INTO schema_migrations (version) VALUES ('20141018211312');

INSERT INTO schema_migrations (version) VALUES ('20141018221851');

INSERT INTO schema_migrations (version) VALUES ('20141019173409');

INSERT INTO schema_migrations (version) VALUES ('20141020010348');

INSERT INTO schema_migrations (version) VALUES ('20141020201847');

INSERT INTO schema_migrations (version) VALUES ('20141020202130');

INSERT INTO schema_migrations (version) VALUES ('20141022073731');

INSERT INTO schema_migrations (version) VALUES ('20141022223458');

INSERT INTO schema_migrations (version) VALUES ('20141024160514');

INSERT INTO schema_migrations (version) VALUES ('20141024161527');

INSERT INTO schema_migrations (version) VALUES ('20141024161853');

INSERT INTO schema_migrations (version) VALUES ('20141024162017');

INSERT INTO schema_migrations (version) VALUES ('20141024202018');

INSERT INTO schema_migrations (version) VALUES ('20141025012607');

INSERT INTO schema_migrations (version) VALUES ('20141028004812');

INSERT INTO schema_migrations (version) VALUES ('20141028004947');

INSERT INTO schema_migrations (version) VALUES ('20141028005032');

INSERT INTO schema_migrations (version) VALUES ('20141031065827');

INSERT INTO schema_migrations (version) VALUES ('20141105213337');

INSERT INTO schema_migrations (version) VALUES ('20141108061241');

INSERT INTO schema_migrations (version) VALUES ('20141108061358');

INSERT INTO schema_migrations (version) VALUES ('20141110052046');

INSERT INTO schema_migrations (version) VALUES ('20141203055727');

INSERT INTO schema_migrations (version) VALUES ('20141207233358');

INSERT INTO schema_migrations (version) VALUES ('20141208042953');

INSERT INTO schema_migrations (version) VALUES ('20141209195548');

INSERT INTO schema_migrations (version) VALUES ('20141211215700');

INSERT INTO schema_migrations (version) VALUES ('20141211220733');

INSERT INTO schema_migrations (version) VALUES ('20141212012458');

INSERT INTO schema_migrations (version) VALUES ('20141212074856');

INSERT INTO schema_migrations (version) VALUES ('20141218213438');

INSERT INTO schema_migrations (version) VALUES ('20141221184427');

INSERT INTO schema_migrations (version) VALUES ('20141224222352');

INSERT INTO schema_migrations (version) VALUES ('20141229224709');

INSERT INTO schema_migrations (version) VALUES ('20141230021947');

INSERT INTO schema_migrations (version) VALUES ('20150119174754');

INSERT INTO schema_migrations (version) VALUES ('20150119181243');

INSERT INTO schema_migrations (version) VALUES ('20150119202722');

INSERT INTO schema_migrations (version) VALUES ('20150119234706');

INSERT INTO schema_migrations (version) VALUES ('20150127204908');

INSERT INTO schema_migrations (version) VALUES ('20150129033340');

INSERT INTO schema_migrations (version) VALUES ('20150129045244');

INSERT INTO schema_migrations (version) VALUES ('20150129045517');

INSERT INTO schema_migrations (version) VALUES ('20150129045718');

INSERT INTO schema_migrations (version) VALUES ('20150131041859');

INSERT INTO schema_migrations (version) VALUES ('20150131192714');

INSERT INTO schema_migrations (version) VALUES ('20150203223327');

INSERT INTO schema_migrations (version) VALUES ('20150203224112');

INSERT INTO schema_migrations (version) VALUES ('20150203232838');

INSERT INTO schema_migrations (version) VALUES ('20150203235151');

INSERT INTO schema_migrations (version) VALUES ('20150204004729');

INSERT INTO schema_migrations (version) VALUES ('20150204071607');

INSERT INTO schema_migrations (version) VALUES ('20150204185215');

INSERT INTO schema_migrations (version) VALUES ('20150204223303');

INSERT INTO schema_migrations (version) VALUES ('20150204224949');

INSERT INTO schema_migrations (version) VALUES ('20150204235344');

INSERT INTO schema_migrations (version) VALUES ('20150221031941');

INSERT INTO schema_migrations (version) VALUES ('20150222003622');

INSERT INTO schema_migrations (version) VALUES ('20150222180911');

INSERT INTO schema_migrations (version) VALUES ('20150308015831');

INSERT INTO schema_migrations (version) VALUES ('20150308062049');

INSERT INTO schema_migrations (version) VALUES ('20150308062507');

INSERT INTO schema_migrations (version) VALUES ('20150327044758');

INSERT INTO schema_migrations (version) VALUES ('20150328154834');

INSERT INTO schema_migrations (version) VALUES ('20150331050353');

INSERT INTO schema_migrations (version) VALUES ('20150331193942');

INSERT INTO schema_migrations (version) VALUES ('20150401013622');

INSERT INTO schema_migrations (version) VALUES ('20150401014016');

INSERT INTO schema_migrations (version) VALUES ('20150401025031');

INSERT INTO schema_migrations (version) VALUES ('20150403003742');

INSERT INTO schema_migrations (version) VALUES ('20150403171208');

INSERT INTO schema_migrations (version) VALUES ('20150404032349');

INSERT INTO schema_migrations (version) VALUES ('20150404064739');

INSERT INTO schema_migrations (version) VALUES ('20150404194606');

INSERT INTO schema_migrations (version) VALUES ('20150405061904');

INSERT INTO schema_migrations (version) VALUES ('20150407003407');

INSERT INTO schema_migrations (version) VALUES ('20150407065950');

INSERT INTO schema_migrations (version) VALUES ('20150407203957');

INSERT INTO schema_migrations (version) VALUES ('20150410034907');

INSERT INTO schema_migrations (version) VALUES ('20150411063859');

INSERT INTO schema_migrations (version) VALUES ('20150411193039');

INSERT INTO schema_migrations (version) VALUES ('20150411193339');

INSERT INTO schema_migrations (version) VALUES ('20150411211209');

INSERT INTO schema_migrations (version) VALUES ('20150412014816');

INSERT INTO schema_migrations (version) VALUES ('20150412015258');

INSERT INTO schema_migrations (version) VALUES ('20150412195517');

INSERT INTO schema_migrations (version) VALUES ('20150414093557');

INSERT INTO schema_migrations (version) VALUES ('20150417212439');

INSERT INTO schema_migrations (version) VALUES ('20150419224339');

INSERT INTO schema_migrations (version) VALUES ('20150423033019');

INSERT INTO schema_migrations (version) VALUES ('20150423205412');

INSERT INTO schema_migrations (version) VALUES ('20150423215434');

INSERT INTO schema_migrations (version) VALUES ('20150423235150');

INSERT INTO schema_migrations (version) VALUES ('20150424000213');

INSERT INTO schema_migrations (version) VALUES ('20150424033802');

INSERT INTO schema_migrations (version) VALUES ('20150424104620');

INSERT INTO schema_migrations (version) VALUES ('20150430064840');

INSERT INTO schema_migrations (version) VALUES ('20150430070028');

INSERT INTO schema_migrations (version) VALUES ('20150430232038');

INSERT INTO schema_migrations (version) VALUES ('20150512173615');

INSERT INTO schema_migrations (version) VALUES ('20150513155830');

INSERT INTO schema_migrations (version) VALUES ('20150513174509');

INSERT INTO schema_migrations (version) VALUES ('20150518202448');

INSERT INTO schema_migrations (version) VALUES ('20150518203414');

INSERT INTO schema_migrations (version) VALUES ('20150519040539');

INSERT INTO schema_migrations (version) VALUES ('20150520161423');

INSERT INTO schema_migrations (version) VALUES ('20150520163416');

INSERT INTO schema_migrations (version) VALUES ('20150520233215');

INSERT INTO schema_migrations (version) VALUES ('20150520234427');

INSERT INTO schema_migrations (version) VALUES ('20150521013659');

INSERT INTO schema_migrations (version) VALUES ('20150521014917');

INSERT INTO schema_migrations (version) VALUES ('20150521044801');

INSERT INTO schema_migrations (version) VALUES ('20150521151419');

INSERT INTO schema_migrations (version) VALUES ('20150523002702');

INSERT INTO schema_migrations (version) VALUES ('20150523174319');

INSERT INTO schema_migrations (version) VALUES ('20150528032752');

INSERT INTO schema_migrations (version) VALUES ('20150602193418');

INSERT INTO schema_migrations (version) VALUES ('20150610133455');

INSERT INTO schema_migrations (version) VALUES ('20150612234538');

INSERT INTO schema_migrations (version) VALUES ('20150613003129');

INSERT INTO schema_migrations (version) VALUES ('20150613030906');

INSERT INTO schema_migrations (version) VALUES ('20150613173754');

INSERT INTO schema_migrations (version) VALUES ('20150613235612');

INSERT INTO schema_migrations (version) VALUES ('20150618012109');

INSERT INTO schema_migrations (version) VALUES ('20150618012324');

INSERT INTO schema_migrations (version) VALUES ('20150618054845');

INSERT INTO schema_migrations (version) VALUES ('20150618173816');

INSERT INTO schema_migrations (version) VALUES ('20150620044049');

INSERT INTO schema_migrations (version) VALUES ('20150626164013');

INSERT INTO schema_migrations (version) VALUES ('20150626170909');

INSERT INTO schema_migrations (version) VALUES ('20150627065119');

INSERT INTO schema_migrations (version) VALUES ('20150628191213');

INSERT INTO schema_migrations (version) VALUES ('20150628200244');

INSERT INTO schema_migrations (version) VALUES ('20150628232107');

INSERT INTO schema_migrations (version) VALUES ('20150628235149');

INSERT INTO schema_migrations (version) VALUES ('20150629183828');

INSERT INTO schema_migrations (version) VALUES ('20150629225020');

INSERT INTO schema_migrations (version) VALUES ('20150629235406');

INSERT INTO schema_migrations (version) VALUES ('20150701220228');

INSERT INTO schema_migrations (version) VALUES ('20150702214157');

INSERT INTO schema_migrations (version) VALUES ('20150703053142');

INSERT INTO schema_migrations (version) VALUES ('20150704163923');

INSERT INTO schema_migrations (version) VALUES ('20150704185121');

INSERT INTO schema_migrations (version) VALUES ('20150707193459');

INSERT INTO schema_migrations (version) VALUES ('20150725015211');

INSERT INTO schema_migrations (version) VALUES ('20150725235547');

INSERT INTO schema_migrations (version) VALUES ('20150726000918');

INSERT INTO schema_migrations (version) VALUES ('20150726025344');

INSERT INTO schema_migrations (version) VALUES ('20150726030506');

INSERT INTO schema_migrations (version) VALUES ('20150728170038');

INSERT INTO schema_migrations (version) VALUES ('20150728194016');

INSERT INTO schema_migrations (version) VALUES ('20150811201837');

INSERT INTO schema_migrations (version) VALUES ('20150820065030');

INSERT INTO schema_migrations (version) VALUES ('20150820070742');

INSERT INTO schema_migrations (version) VALUES ('20150831224432');

INSERT INTO schema_migrations (version) VALUES ('20150831225529');

INSERT INTO schema_migrations (version) VALUES ('20150904205003');

INSERT INTO schema_migrations (version) VALUES ('20150905172640');

INSERT INTO schema_migrations (version) VALUES ('20150905200942');

INSERT INTO schema_migrations (version) VALUES ('20150908214518');

INSERT INTO schema_migrations (version) VALUES ('20150908225351');

INSERT INTO schema_migrations (version) VALUES ('20150909004904');

INSERT INTO schema_migrations (version) VALUES ('20150910000507');

INSERT INTO schema_migrations (version) VALUES ('20150911170439');

INSERT INTO schema_migrations (version) VALUES ('20150911175028');

INSERT INTO schema_migrations (version) VALUES ('20150911175208');

INSERT INTO schema_migrations (version) VALUES ('20150912142427');

INSERT INTO schema_migrations (version) VALUES ('20150912143808');

INSERT INTO schema_migrations (version) VALUES ('20150914194140');

INSERT INTO schema_migrations (version) VALUES ('20150916011406');

INSERT INTO schema_migrations (version) VALUES ('20150916235102');

INSERT INTO schema_migrations (version) VALUES ('20150917000206');

INSERT INTO schema_migrations (version) VALUES ('20150918222454');

INSERT INTO schema_migrations (version) VALUES ('20150920235938');

INSERT INTO schema_migrations (version) VALUES ('20150921000108');

INSERT INTO schema_migrations (version) VALUES ('20150922210507');

INSERT INTO schema_migrations (version) VALUES ('20150924030550');

INSERT INTO schema_migrations (version) VALUES ('20150926023117');

INSERT INTO schema_migrations (version) VALUES ('20150927041232');

INSERT INTO schema_migrations (version) VALUES ('20150927042718');

INSERT INTO schema_migrations (version) VALUES ('20150928195841');

INSERT INTO schema_migrations (version) VALUES ('20150930172442');

INSERT INTO schema_migrations (version) VALUES ('20151002232701');

INSERT INTO schema_migrations (version) VALUES ('20151002235142');

INSERT INTO schema_migrations (version) VALUES ('20151003001708');

INSERT INTO schema_migrations (version) VALUES ('20151006043139');

INSERT INTO schema_migrations (version) VALUES ('20151006043301');

INSERT INTO schema_migrations (version) VALUES ('20151006071651');

INSERT INTO schema_migrations (version) VALUES ('20151007003808');

INSERT INTO schema_migrations (version) VALUES ('20151007164232');

INSERT INTO schema_migrations (version) VALUES ('20151007165952');

INSERT INTO schema_migrations (version) VALUES ('20151008204828');

INSERT INTO schema_migrations (version) VALUES ('20151009014842');

INSERT INTO schema_migrations (version) VALUES ('20151009050211');

INSERT INTO schema_migrations (version) VALUES ('20151009051458');

INSERT INTO schema_migrations (version) VALUES ('20151009051903');

INSERT INTO schema_migrations (version) VALUES ('20151009211923');

INSERT INTO schema_migrations (version) VALUES ('20151009234155');

INSERT INTO schema_migrations (version) VALUES ('20151010011247');

INSERT INTO schema_migrations (version) VALUES ('20151010021946');

INSERT INTO schema_migrations (version) VALUES ('20151010040137');

INSERT INTO schema_migrations (version) VALUES ('20151010043556');

INSERT INTO schema_migrations (version) VALUES ('20151010045106');

INSERT INTO schema_migrations (version) VALUES ('20151010051215');

INSERT INTO schema_migrations (version) VALUES ('20151010173608');

INSERT INTO schema_migrations (version) VALUES ('20151011012254');

INSERT INTO schema_migrations (version) VALUES ('20151011030652');

INSERT INTO schema_migrations (version) VALUES ('20151011070838');

INSERT INTO schema_migrations (version) VALUES ('20151013070040');

INSERT INTO schema_migrations (version) VALUES ('20151013070217');

INSERT INTO schema_migrations (version) VALUES ('20151014200511');

INSERT INTO schema_migrations (version) VALUES ('20151025172354');

INSERT INTO schema_migrations (version) VALUES ('20151025174244');

INSERT INTO schema_migrations (version) VALUES ('20151026233949');

INSERT INTO schema_migrations (version) VALUES ('20151028195936');

INSERT INTO schema_migrations (version) VALUES ('20151028200345');

INSERT INTO schema_migrations (version) VALUES ('20151028231540');

INSERT INTO schema_migrations (version) VALUES ('20151029004801');

INSERT INTO schema_migrations (version) VALUES ('20151030021906');

INSERT INTO schema_migrations (version) VALUES ('20151030025455');

INSERT INTO schema_migrations (version) VALUES ('20151030035739');

INSERT INTO schema_migrations (version) VALUES ('20151031014546');

INSERT INTO schema_migrations (version) VALUES ('20151031021430');

INSERT INTO schema_migrations (version) VALUES ('20151031024744');

INSERT INTO schema_migrations (version) VALUES ('20151031025015');

INSERT INTO schema_migrations (version) VALUES ('20151031083835');

INSERT INTO schema_migrations (version) VALUES ('20151103071147');

INSERT INTO schema_migrations (version) VALUES ('20151103073516');

INSERT INTO schema_migrations (version) VALUES ('20151103081239');

INSERT INTO schema_migrations (version) VALUES ('20151103102602');

INSERT INTO schema_migrations (version) VALUES ('20151103104710');

INSERT INTO schema_migrations (version) VALUES ('20151104002343');

INSERT INTO schema_migrations (version) VALUES ('20151109052142');

INSERT INTO schema_migrations (version) VALUES ('20151111040621');

INSERT INTO schema_migrations (version) VALUES ('20151111041931');

INSERT INTO schema_migrations (version) VALUES ('20151111042510');

INSERT INTO schema_migrations (version) VALUES ('20151111051755');

INSERT INTO schema_migrations (version) VALUES ('20151113090024');

INSERT INTO schema_migrations (version) VALUES ('20151113094325');

INSERT INTO schema_migrations (version) VALUES ('20151113095834');

INSERT INTO schema_migrations (version) VALUES ('20151115094759');

INSERT INTO schema_migrations (version) VALUES ('20151116065336');

INSERT INTO schema_migrations (version) VALUES ('20151116070817');

INSERT INTO schema_migrations (version) VALUES ('20151116105241');

INSERT INTO schema_migrations (version) VALUES ('20151117123159');

INSERT INTO schema_migrations (version) VALUES ('20151120074938');

INSERT INTO schema_migrations (version) VALUES ('20151120093500');

INSERT INTO schema_migrations (version) VALUES ('20151207033816');

INSERT INTO schema_migrations (version) VALUES ('20151207034249');

INSERT INTO schema_migrations (version) VALUES ('20151207040001');

INSERT INTO schema_migrations (version) VALUES ('20151207041408');

INSERT INTO schema_migrations (version) VALUES ('20151221004602');

INSERT INTO schema_migrations (version) VALUES ('20151226021810');

INSERT INTO schema_migrations (version) VALUES ('20160118164620');

INSERT INTO schema_migrations (version) VALUES ('20160125214512');

INSERT INTO schema_migrations (version) VALUES ('20160127032337');

INSERT INTO schema_migrations (version) VALUES ('20160128160636');

INSERT INTO schema_migrations (version) VALUES ('20160130173452');

INSERT INTO schema_migrations (version) VALUES ('20160130204920');

INSERT INTO schema_migrations (version) VALUES ('20160131021144');

INSERT INTO schema_migrations (version) VALUES ('20160207222129');

INSERT INTO schema_migrations (version) VALUES ('20160210163325');

INSERT INTO schema_migrations (version) VALUES ('20160210213700');

INSERT INTO schema_migrations (version) VALUES ('20160211205444');

INSERT INTO schema_migrations (version) VALUES ('20160215202907');

INSERT INTO schema_migrations (version) VALUES ('20160220064304');

INSERT INTO schema_migrations (version) VALUES ('20160221014119');

INSERT INTO schema_migrations (version) VALUES ('20160223171025');

INSERT INTO schema_migrations (version) VALUES ('20160227235518');

INSERT INTO schema_migrations (version) VALUES ('20160228024412');

INSERT INTO schema_migrations (version) VALUES ('20160228030312');

INSERT INTO schema_migrations (version) VALUES ('20160228223830');

INSERT INTO schema_migrations (version) VALUES ('20160228224625');

INSERT INTO schema_migrations (version) VALUES ('20160229043538');

INSERT INTO schema_migrations (version) VALUES ('20160229170236');

INSERT INTO schema_migrations (version) VALUES ('20160302055418');

INSERT INTO schema_migrations (version) VALUES ('20160302081315');

INSERT INTO schema_migrations (version) VALUES ('20160304054607');

INSERT INTO schema_migrations (version) VALUES ('20160305202505');

INSERT INTO schema_migrations (version) VALUES ('20160311062925');

INSERT INTO schema_migrations (version) VALUES ('20160311063220');

INSERT INTO schema_migrations (version) VALUES ('20160311194214');

INSERT INTO schema_migrations (version) VALUES ('20160314033653');

INSERT INTO schema_migrations (version) VALUES ('20160314185258');

INSERT INTO schema_migrations (version) VALUES ('20160315043952');

INSERT INTO schema_migrations (version) VALUES ('20160315063118');

INSERT INTO schema_migrations (version) VALUES ('20160315070023');

INSERT INTO schema_migrations (version) VALUES ('20160315200751');

INSERT INTO schema_migrations (version) VALUES ('20160315201237');

INSERT INTO schema_migrations (version) VALUES ('20160315210035');

INSERT INTO schema_migrations (version) VALUES ('20160315213703');

INSERT INTO schema_migrations (version) VALUES ('20160317031738');

INSERT INTO schema_migrations (version) VALUES ('20160318044218');

INSERT INTO schema_migrations (version) VALUES ('20160322030648');

INSERT INTO schema_migrations (version) VALUES ('20160323043452');

INSERT INTO schema_migrations (version) VALUES ('20160323045637');

INSERT INTO schema_migrations (version) VALUES ('20160329211754');

INSERT INTO schema_migrations (version) VALUES ('20160330002143');

INSERT INTO schema_migrations (version) VALUES ('20160331043355');

INSERT INTO schema_migrations (version) VALUES ('20160401205010');

INSERT INTO schema_migrations (version) VALUES ('20160402184207');

INSERT INTO schema_migrations (version) VALUES ('20160405012924');

INSERT INTO schema_migrations (version) VALUES ('20160405024037');

INSERT INTO schema_migrations (version) VALUES ('20160405042050');

INSERT INTO schema_migrations (version) VALUES ('20160406042726');

INSERT INTO schema_migrations (version) VALUES ('20160407014404');

INSERT INTO schema_migrations (version) VALUES ('20160407030606');

INSERT INTO schema_migrations (version) VALUES ('20160407032951');

INSERT INTO schema_migrations (version) VALUES ('20160407060435');

INSERT INTO schema_migrations (version) VALUES ('20160408213113');

INSERT INTO schema_migrations (version) VALUES ('20160409031341');

INSERT INTO schema_migrations (version) VALUES ('20160409050957');

INSERT INTO schema_migrations (version) VALUES ('20160409062352');

INSERT INTO schema_migrations (version) VALUES ('20160409192838');

INSERT INTO schema_migrations (version) VALUES ('20160411035147');

INSERT INTO schema_migrations (version) VALUES ('20160411205229');

INSERT INTO schema_migrations (version) VALUES ('20160416025159');

INSERT INTO schema_migrations (version) VALUES ('20160416042909');

INSERT INTO schema_migrations (version) VALUES ('20160416214140');

INSERT INTO schema_migrations (version) VALUES ('20160417031410');

INSERT INTO schema_migrations (version) VALUES ('20160417191546');

INSERT INTO schema_migrations (version) VALUES ('20160417233907');

INSERT INTO schema_migrations (version) VALUES ('20160418180605');

INSERT INTO schema_migrations (version) VALUES ('20160420162525');

INSERT INTO schema_migrations (version) VALUES ('20160420173733');

INSERT INTO schema_migrations (version) VALUES ('20160421054900');

INSERT INTO schema_migrations (version) VALUES ('20160422023421');

INSERT INTO schema_migrations (version) VALUES ('20160422031504');

INSERT INTO schema_migrations (version) VALUES ('20160422205735');

INSERT INTO schema_migrations (version) VALUES ('20160429171901');

INSERT INTO schema_migrations (version) VALUES ('20160508001633');

INSERT INTO schema_migrations (version) VALUES ('20160508013118');

INSERT INTO schema_migrations (version) VALUES ('20160509232959');

INSERT INTO schema_migrations (version) VALUES ('20160510041828');

INSERT INTO schema_migrations (version) VALUES ('20160510181231');

INSERT INTO schema_migrations (version) VALUES ('20160511022316');

INSERT INTO schema_migrations (version) VALUES ('20160511045047');

INSERT INTO schema_migrations (version) VALUES ('20160512232811');

INSERT INTO schema_migrations (version) VALUES ('20160513000853');

INSERT INTO schema_migrations (version) VALUES ('20160513002644');

INSERT INTO schema_migrations (version) VALUES ('20160513054655');

INSERT INTO schema_migrations (version) VALUES ('20160513214021');

INSERT INTO schema_migrations (version) VALUES ('20160514040533');

INSERT INTO schema_migrations (version) VALUES ('20160525033919');

INSERT INTO schema_migrations (version) VALUES ('20160525173659');

INSERT INTO schema_migrations (version) VALUES ('20160525200206');

INSERT INTO schema_migrations (version) VALUES ('20160526033814');

INSERT INTO schema_migrations (version) VALUES ('20160526180659');

