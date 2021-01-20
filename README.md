# Sobre
Uma API em Delphi Datasnap para o programa PHP CodeIgniter 4

# Como usar
Esta API disponibiliza uma interface facilitada para operações básicas (CRUD) no banco de dados Firebird. 
Ao rodar o programa, você terá uma interface gráfica GUI para configurar a porta e abrir o servidor. 
O endpoint comum para todos os métodos ficará em "https://localhost:PORTA/datasnap/rest/", os próximos parâmetros serão,
nesta ordem, a unidade de ServerMethods (Aqui chamada de TMS), o método em questão (Temos por exemplo Cliente) e então os parâmetros seguintes.

## Verbos HTTP
O DataSnap identifica os verbos http e os direciona para os métodos de acordo com seus prefixos. Por exemplo o método Cliente terá 4 funções
uma para cada verbo:
- function Cliente...       GET
- function updateCliente... POST
- function acceptCliente... PUT
- function cancelCliente... DELETE
