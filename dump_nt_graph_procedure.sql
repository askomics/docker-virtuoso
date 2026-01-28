CREATE PROCEDURE dump_nt_graph
  ( IN  srcgraph           VARCHAR
  , IN  out_file           VARCHAR
  , IN  file_length_limit  INTEGER  := 1000000000
  ) {
    DECLARE  env,  ses           ANY;
    DECLARE  ses_len
          ,  max_ses_len
          ,  file_len      INTEGER;
    SET ISOLATION = 'uncommitted';
    max_ses_len  := 10000000;
    file_len     := 0;
    string_to_file (
        out_file,
        sprintf ( '# Dump of graph <%s>, as of %s\n@base <> .\n',
                  srcgraph, CAST (NOW() AS VARCHAR) ),
        -2
    );
    env := vector (0, 0, 0);
    ses := string_output ();
    FOR (SELECT * FROM ( SPARQL DEFINE input:storage ""
                         SELECT ?s ?p ?o { GRAPH `iri(?:srcgraph)` { ?s ?p ?o } }
                       ) AS sub OPTION (LOOP)) DO {
        http_nt_triple (env, "s", "p", "o", ses);
        ses_len := length (ses);
        IF (ses_len > max_ses_len) {
            file_len := file_len + ses_len;
            IF (file_len > file_length_limit) {
                string_to_file (out_file, ses, -1);
                file_len := 0;
                env := vector (0, 0, 0);
            } ELSE {
                string_to_file (out_file, ses, -1);
            }
            ses := string_output ();
        }
    }
    IF (LENGTH (ses)) {
        string_to_file (out_file, ses, -1);
        gz_compress_file (out_file, out_file||'.gz');
        file_delete (out_file);
    }
};
