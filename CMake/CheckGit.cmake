set(CURRENT_LIST_DIR ${CMAKE_CURRENT_LIST_DIR})

set(SE_GIT_COMMIT_HASH_INPUT_FILE ${SE_GIT_COMMIT_HASH_INPUT_DIR}/GitCommitHash.cpp.in)
set(SE_GIT_COMMIT_HASH_OUTPUT_FILE ${SE_GIT_COMMIT_HASH_OUTPUT_DIR}/GitCommitHash.cpp)

function(CheckGitWrite git_hash)
    file(WRITE ${SE_BUILD}/GitCommitHashCache.txt ${git_hash})
endfunction()

function(CheckGitRead git_hash)
    if (EXISTS ${SE_BUILD}/GitCommitHashCache.txt)
        file(STRINGS ${SE_BUILD}/GitCommitHashCache.txt CONTENT)
        LIST(GET CONTENT 0 var)
        set(${git_hash} ${var} PARENT_SCOPE)
    endif ()
endfunction()

function(CheckGitCommitHash)
    # Get the latest abbreviated commit hash of the working branch
    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT_VARIABLE GIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    
    set(GIT_HASH_CACHE "unknown")
    CheckGitRead("GIT_HASH_CACHE")
    if (NOT EXISTS ${SE_GIT_COMMIT_HASH_OUTPUT_DIR})
        file(MAKE_DIRECTORY ${SE_GIT_COMMIT_HASH_OUTPUT_DIR})
    endif ()

    if (NOT EXISTS ${SE_GIT_COMMIT_HASH_OUTPUT_DIR}/GitCommitHash.h)
        file(COPY ${SE_GIT_COMMIT_HASH_INPUT_DIR}/GitCommitHash.h DESTINATION ${SE_GIT_COMMIT_HASH_OUTPUT_DIR})
    endif()

    # Only update the git_version.cpp if the hash has changed. This will
    # prevent us from rebuilding the project more than we need to.
    if (NOT ${GIT_HASH} STREQUAL ${GIT_HASH_CACHE} OR NOT EXISTS ${SE_GIT_COMMIT_HASH_OUTPUT_FILE})
        # Set che GIT_HASH_CACHE variable the next build won't have
        # to regenerate the source file.
        CheckGitWrite(${GIT_HASH})

        configure_file(${SE_GIT_COMMIT_HASH_INPUT_FILE} ${SE_GIT_COMMIT_HASH_OUTPUT_FILE} @ONLY)
    endif ()

endfunction()

function(CheckGitSetup)
    CheckGitCommitHash()

    add_custom_target(AlwaysCheckGit COMMAND ${CMAKE_COMMAND}
        -DRUN_CHECK_GIT_VERSION=1
        -DSE_GIT_COMMIT_HASH_INPUT_DIR=${SE_GIT_COMMIT_HASH_INPUT_DIR}
        -DSE_GIT_COMMIT_HASH_OUTPUT_DIR=${SE_GIT_COMMIT_HASH_OUTPUT_DIR}
        -DSE_BUILD=${SE_BUILD}
        -DGIT_HASH_CACHE=${GIT_HASH_CACHE}
        -P ${CURRENT_LIST_DIR}/CheckGit.cmake
        BYPRODUCTS ${SE_GIT_COMMIT_HASH_OUTPUT_FILE}
        )
    
    if(NOT(EXISTS "${SE_GIT_COMMIT_HASH_OUTPUT_DIR}"))
        file(MAKE_DIRECTORY "${SE_GIT_COMMIT_HASH_OUTPUT_DIR}")
    endif()    
    if(NOT(EXISTS "${SE_GIT_COMMIT_HASH_OUTPUT_DIR}/GitCommitHash.cpp"))
        file(COPY ${SE_GIT_COMMIT_HASH_INPUT_DIR}/GitCommitHash.cpp.default DESTINATION ${SE_GIT_COMMIT_HASH_OUTPUT_DIR})
        file(RENAME ${SE_GIT_COMMIT_HASH_OUTPUT_DIR}/GitCommitHash.cpp.default ${SE_GIT_COMMIT_HASH_OUTPUT_DIR}/GitCommitHash.cpp)
    endif()
    
    add_library(SEGitCommitHash SHARED ${SE_GIT_COMMIT_HASH_OUTPUT_DIR}/GitCommitHash.h ${SE_GIT_COMMIT_HASH_OUTPUT_DIR}/GitCommitHash.cpp)
    target_include_directories(SEGitCommitHash PUBLIC ${SE_BUILD}/GitCommitHash)
    add_dependencies(SEGitCommitHash AlwaysCheckGit)
endfunction()

# This is used to run this function from an external cmake process.
if (RUN_CHECK_GIT_VERSION)
    CheckGitCommitHash()
endif ()