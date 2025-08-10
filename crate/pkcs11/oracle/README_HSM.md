# Oracle Key Vault integration notes

Links:

- Thalès:
  * <https://thalesdocs.com/ctp/con/cakm/cakm-oracle-tde/latest/admin/tde-integrating_19c/index.html#configuring-hsm-wallet-on-fresh-setup>
  * <https://www.thalesdocs.com/gphsm/integrations/guides/oracle_database/index.html>

- IBM:
  - <https://www.ibm.com/docs/en/gklm/4.2.1?topic=setup-enabling-auto-login-oracle-wallet>

- Futurex:

* <https://docs.futurex.com/hsm-integration-guides/appendix-migrate-from-a-software-keystore-to-an-hsm-keystore>

- Administration of TDE for Oracle Database:
  * <https://docs.oracle.com/en/database/oracle/oracle-database/23/dbtde/configuring-united-mode2.html#GUID-D3045557-FA85-4EA5-A85A-75EAE9D67E13>
  * <https://docs.oracle.com/en/database/oracle/oracle-database/19/asoag/configuring-transparent-data-encryption.html#GUID-F098129B-BBFF-4C86-B119-80AB706DB2A1>
  * <https://docs.oracle.com/en/database/oracle/oracle-database/23/rilin/setting-the-oracle-user-environment-variables.html>
  * <https://docs.oracle.com/en/database/oracle/oracle-database/19/asoag/managing-keystores-encryption-keys-in-united-mode.html#GUID-D3045557-FA85-4EA5-A85A-75EAE9D67E13>
  * <https://docs.oracle.com/en/database/oracle/oracle-database/18/refrn/WALLET_ROOT.html>

- Pull official docker Oracle database: <https://container-registry.oracle.com/ords/f?p=113:4:106545702571334:::4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:1863,1863,Oracle%20Database%20Free,Oracle%20Database%20Free,1,0&cs=3Ti6PWKfgzS30ZJfMaoHY1WKna0Ss_mxMjkSQqTBI7AfugrE1tN9BilNn74Z9ynq_5THQFpwXGPfVnPbkILvCiw>
- Set the encryption on DB: <https://bryangrenn.blogspot.com/2021/04/migrating-your-tde-wallet-to-oracle-key.html>
- Example of encryption on DB: <https://blog.capdata.fr/index.php/le-chiffrement-oracle-transparent-data-encryption-sur-oracle-19c/>

- Administration of ASM:
  - <https://docs.oracle.com/en/database/oracle/oracle-database/23/ostmg/admin-asm-diskgroups.html#OSTMG137>
  - <https://thalesdocs.com/ctp/cte-con/cte/7.4.0/integrations/lin-int/lin-int-oracle/lin-int-rac/index.html>
Configure the Cosmian CLI configuration for oracle user (/home/oracle/.cosmian/config.toml):

```sh
[kms_config.http_config]
server_url = "http://kms:9998"

[findex_config.http_config]
server_url = "http://kms:6668"
```

## Install Oracle Database 23.1 using docker container

Example using docker-compose.yml:

```yaml

  oracle:
    container_name: oracle
    image: container-registry.oracle.com/database/free:latest
    ports:
      - 1521:1521
    environment:
      ORACLE_PWD: 1234
      ENABLE_ARCHIVELOG: true
      ENABLE_FORCE_LOGGING: true
    volumes:
      - ./oradata:/opt/oracle/oradata
      - ./keystore:/opt/oracle/keystore
```

Prepare docker volumes permissions:

```sh
sudo chown -R oracle:oinstall /opt/oracle/oradata
sudo chown -R oracle:oinstall /opt/oracle/keystore
```

Copy Cosmian DLL to the container:

```sh
docker cp libcosmian_pkcs11.so oracle:/home/oracle/
docker exec -it oracle bash -c "chown -R oracle:oinstall /home/oracle/libcosmian_pkcs11.so"
```

To connect to the database at the CDB$ROOT level as sysdba:

```sh
sqlplus sys/<your password>@//localhost:<port mapped to 1521>/FREE as sysdba
docker exec -it oracle sqlplus sys/1234@FREE as sysdba
ALTER SYSTEM SET WALLET_ROOT='/opt/oracle/extapi/64/hsm/Cosmian/libcosmian_pkcs11.so' SCOPE = SPFILE;
SHUTDOWN IMMEDIATE
STARTUP
ALTER SYSTEM SET TDE_CONFIGURATION="KEYSTORE_CONFIGURATION=HSM" SCOPE=BOTH SID='*';
```

Open the keystore:

```sql
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY hsm_identity_pass;
```

```sql
# Create the master key
ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY hsm_identity_pass;
```

Create a database (if required):

CONNECT SYS AS SYSDBA
CREATE DATABASE test_db
     DATAFILE 'test_system' SIZE 10M
     LOGFILE GROUP 1 ('test_log1a', 'test_log1b') SIZE 500K,
     GROUP 2 ('test_log2a', 'test_log2b') SIZE 500K;

CREATE USER C##u1 IDENTIFIED BY pwd1 DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON USERS CONTAINER=ALL;
GRANT CREATE SESSION to C##u1;
GRANT CREATE TABLE TO C##u1;

Connect as normal user:

```sh
docker exec -it oracle sqlplus C##u1/pwd1@FREE
```

```sql
create table infos_employes (prenom varchar2(40),  nom varchar2(40),
  address varchar2(40) encrypt using 'AES256',
  code_postal number(6) encrypt using 'AES256');
insert into infos_employes values ('Emmanuel','Rami','19 rue Crebillon Nantes','44000');
```

Check the encryption on columns:

```sql
connect SYS as SYSDBA;
select * from dba_encrypted_columns;
````

Check in trace that columns are encrypted:

```sql
select rowid from infos_employes where NOM='Rami';
select DBMS_ROWID.ROWID_BLOCK_NUMBER('AAARriAAAAAAAMNAAA') "Block number" from DUAL;
select DBMS_ROWID.ROWID_BLOCK_NUMBER('AAARq2AAAAAAAMLAAA') "Block number" from DUAL;
alter system dump datafile 7 block 781;
```

```sh
# check last trace file
ls -alt /opt/oracle/diag/rdbms/free/FREE/trace/FREE_*
cat /opt/oracle/diag/rdbms/free/FREE/trace/FREE_ora_42690.trc
Dump of memory from 0x7bb9f6fcf000 to 0x7bb9f6fd1000
7BB9F6FCF000 0000A206 0000030D 003368F4 04030000  [.........h3.....]
7BB9F6FCF010 00003D97 00400301 00011AE2 003368F4  [.=....@......h3.]
7BB9F6FCF020 00008000 00320002 00000308 00170002  [......2.........]
7BB9F6FCF030 00000345 0000043D 001700CB 00000001  [E...=...........]
7BB9F6FCF040 00000000 00000000 00000000 00000000  [................]
        Repeat 1 times
7BB9F6FCF060 00000000 00010100 0014FFFF 1EF91F0D  [................]
7BB9F6FCF070 00001EF9 1F0D0001 00000000 00000000  [................]
7BB9F6FCF080 00000000 00000000 00000000 00000000  [................]
        Repeat 494 times
7BB9F6FD0F70 04012C00 6D6D4508 65756E61 6152046C  [.,...Emmanuel.Ra]
7BB9F6FD0F80 DA44696D 12C3B171 401428BB 94A00122  [miD.q....(.@"...]
7BB9F6FD0F90 4B1404B3 A9A60247 8E83EDC9 FF4B00E6  [...KG.........K.]
7BB9F6FD0FA0 EB0AEAA2 0DCD80CC 74B76A49 58BB6409  [........Ij.t.d.X]
7BB9F6FD0FB0 8AFC82EF EFCAD9E4 57F852B7 A475DD22  [.........R.W".u.]
7BB9F6FD0FC0 81C7E986 341FD58D 80147AAD A951EB8A  [.......4.z....Q.]
7BB9F6FD0FD0 85E287F8 1AA8C6BF 42893EE8 512CDF0F  [.........>.B..,Q]
7BB9F6FD0FE0 EED2CD1B C69B4F9C 24BD6BFD DFBED941  [.....O...k.$A...]
7BB9F6FD0FF0 7CC500C4 B6FE27D6 F788661E 68F40603  [...|.'...f.....h]

```

Compare with clear table:

```sql
connect C##u1
create table infos_societies (nom varchar2(40),
  reason varchar2(40),
  address varchar2(40),
  code_postal number(6) );
insert into infos_societies values ('Capdata','SA','9 rue de la porte de Buc Versailles','78000');
select rowid from infos_societies where NOM='Capdata';
select DBMS_ROWID.ROWID_BLOCK_NUMBER('AAARruAAAAAAAMWAAA') "Block number" from DUAL;
alter system dump datafile 7 block 790;
```

```sh
ls -alt /opt/oracle/diag/rdbms/free/FREE/trace/

Dump of memory from 0x76d822c0a000 to 0x76d822c0c000
76D822C0A000 0000A206 00000316 003412CE 04030000  [..........4.....]
76D822C0A010 00006614 00000001 00011AEE 003412CE  [.f............4.]
76D822C0A020 00008000 00320002 00000310 001A0001  [......2.........]
76D822C0A030 0000032F 0000084F 003100AB 00000001  [/...O.....1.....]
76D822C0A040 00000000 00000000 00000000 00000000  [................]
        Repeat 1 times
76D822C0A060 00000000 00010100 0014FFFF 1F4E1F62  [............b.N.]
76D822C0A070 00001F4E 1F620001 00000000 00000000  [N.....b.........]
76D822C0A080 00000000 00000000 00000000 00000000  [................]
        Repeat 499 times
76D822C0BFC0 00000000 012C0000 61430704 74616470  [......,...Capdat]
76D822C0BFD0 41530261 72203923 64206575 616C2065  [a.SA#9 rue de la]
76D822C0BFE0 726F7020 64206574 75422065 65562063  [ porte de Buc Ve]
76D822C0BFF0 69617372 73656C6C 5108C303 12CE0603  [rsailles...Q....]
```
