# Se carga con `source`: activa OneAgent application-only en los procesos de la app si está instalado.
DT_AGENT_LIB_PATH=/opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so
if [[ -f "$DT_AGENT_LIB_PATH" ]]; then
  export DT_AGENT_LIB="$DT_AGENT_LIB_PATH"
  echo ">> Dynatrace OneAgent (application-only) activo"
else
  unset DT_AGENT_LIB
fi
