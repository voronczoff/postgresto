--liquibase formatted sql
--changeset framework:refresh_search_index runAlways:true runInTransaction:false logicalFilePath:data/cumulative_changelog.xml

SELECT count(*) FROM postgresto.search_refresh();
