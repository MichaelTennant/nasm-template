project_name=nasm-example
project_dir=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

src_dir=${project_dir}/src
build_dir=${project_dir}/build

target_src=${src_dir}/main.asm
target_obj=${build_dir}/${project_name}.o
target_bin=${build_dir}/${project_name}

asm=nasm
asm_includes=
asm_flags=-f elf64
asm_debug_flags=-g -Fdwarf

cc=gcc
cc_flags=-fPIE
cc_libraries=

.PHONY: all
all: assemble link

.PHONY: assemble
assemble: ${target_src}
	mkdir -p ${build_dir}
	${asm} ${asm_includes} ${asm_flags} ${asm_debug_flags} -o ${target_obj} ${target_src}

.PHONY: link
link: ${target_obj}
	${cc} ${cc_libraries} ${cc_flags} -o ${target_bin} ${target_obj}

.PHONY: clean
clean: all
	rm -f ${target_obj}
