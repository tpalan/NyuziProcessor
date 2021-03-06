//
// Copyright 2016 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include "mmu_test_common.inc"

//
// Validate proper address space identifier (ASID) operation.
// Allocate two ASIDs, then add a TLB entry for each. The two TLB entries have
// the same virtual address, but map to different physical addresses. Switch
// between the two address spaces and read from the address in each to ensure
// the proper physical page is mapped. This test also implicitly validates that
// the global TLB bit is observed and those entries appear in both address
// spaces (The test would fail in the second address space if not, because
// the code pages wouldn't be mapped).
//

                .globl _start
_start:         // Set up first TLB page
                li s0, 0x1000
                li s1, 0x1000 | TLB_PRESENT | TLB_GLOBAL | TLB_EXECUTABLE | TLB_WRITABLE
                dtlbinsert s0, s1
                itlbinsert s0, s1
                li s0, 0xffff0000
                li s1, 0xffff0000 | TLB_PRESENT | TLB_GLOBAL | TLB_WRITABLE
                dtlbinsert s0, s1

                // Map page into ASID 1
                move s0, 1
                setcr s0, CR_CURRENT_ASID
                li s0, 0x2000
                li s1, 0x2000 | TLB_PRESENT
                dtlbinsert s0, s1

                // Write value
                li s2, 0xbe8ab8a
                store_32 s2, (s0)

                // Map page into ASID 2
                move s0, 2
                setcr s0, CR_CURRENT_ASID
                li s0, 0x2000
                li s1, 0x3000 | TLB_PRESENT
                dtlbinsert s0, s1

                // Write value
                li s0, 0x3000
                li s2, 0x31c126de
                store_32 s2, (s0)

                // Enable MMU
                move s0, FLAG_MMU_EN | FLAG_SUPERVISOR_EN
                setcr s0, CR_FLAGS
                flush_pipeline

                // Read from address space 1
                li s1, 0x2000
                move s0, 1
                setcr s0, CR_CURRENT_ASID
                flush_pipeline

                load_32 s0, (s1)
                assert_reg s0, 0xbe8ab8a

                // Read from address space 2
                move s0, 2
                setcr s0, CR_CURRENT_ASID
                flush_pipeline

                load_32 s0, (s1)
                assert_reg s0, 0x31c126de

                call pass_test
