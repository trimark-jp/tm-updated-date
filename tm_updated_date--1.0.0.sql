\echo Use "CREATE EXTENSION tm_updated_date" to load this file. \quit

-- BASE TABLE for updated date.
CREATE TABLE tm_updated_date (
    updated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE
);

-- This is a marker for exclusion from trigger target.
CREATE TABLE tm_updated_date_no_trigger (
);


-- UPDATE 'created_at' and 'updated_at'
CREATE OR REPLACE FUNCTION tm_updated_date_trigger_func()
RETURNS TRIGGER AS $tm_updated_date_trigger_func$
DECLARE
    current_timestamp TIMESTAMP WITH TIME ZONE = NOW();
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at = current_timestamp;
    END IF;
    NEW.updated_at = current_timestamp;
    RETURN NEW;
END;
$tm_updated_date_trigger_func$ LANGUAGE plpgsql;


-- MAKE TRIGGER FOR input_table_name.
CREATE OR REPLACE FUNCTION tm_make_updated_date_trigger_for(
    input_table_name NAME
) RETURNS VOID AS $tm_make_updated_date_trigger_for$
DECLARE
BEGIN
    -- DROP OLD TABLE
    EXECUTE 'DROP TRIGGER IF EXISTS tm_updated_date_trigger ON ' || input_table_name || ' CASCADE';

    -- CREATE TRIGGER
    EXECUTE 'CREATE TRIGGER tm_updated_date_trigger BEFORE INSERT OR UPDATE ON ' || input_table_name ||
        ' FOR EACH ROW EXECUTE PROCEDURE tm_updated_date_trigger_func()';
END;
$tm_make_updated_date_trigger_for$ LANGUAGE plpgsql;



-- make triggers for all tables inherits from tm_updated_date.
CREATE OR REPLACE FUNCTION tm_make_updated_date_triggers(
    input_schema_name NAME DEFAULT 'public'
) RETURNS SETOF NAME AS $tm_make_updated_date_triggers$
DECLARE
    exclude_oid OID;
    current_table_name NAME;
BEGIN
    exclude_oid := tm_name_to_oid('tm_updated_date_no_trigger');

    FOR current_table_name IN
        SELECT * FROM tm_find_tables_inherit_from('tm_updated_date', input_schema_name)
    LOOP
        IF exclude_oid IS NOT NULL THEN
            CONTINUE WHEN tm_is_inherit_from(tm_name_to_oid(current_table_name), exclude_oid);
        END IF;

        PERFORM tm_make_updated_date_trigger_for(current_table_name);
        RETURN NEXT current_table_name;
    END LOOP;
END;
$tm_make_updated_date_triggers$ LANGUAGE plpgsql;