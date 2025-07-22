import { loadImageDirToDocker } from "{{ LIB }}";

const load = () => loadImageDirToDocker("{{ IMAGE }}");
export default load;
