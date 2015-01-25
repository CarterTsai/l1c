open HolKernel boolLib bossLib listTheory Parse IndDefLib finite_mapTheory relationTheory arithmeticTheory l1Theory il1Theory pred_setTheory pairTheory lcsymtacs prim_recTheory integerTheory;

val _ = new_theory "l1_to_il1";

val contains_expr_def = Define `
    (contains_expr l (IL1_Value v) = F) /\
    (contains_expr l (IL1_Plus e1 e2) = contains_expr l e1 \/ contains_expr l e2) /\
    (contains_expr l (IL1_Geq e1 e2) = contains_expr l e1 \/ contains_expr l e2) /\
    (contains_expr l1 (IL1_Deref l2) = (l1 = l2)) /\
    (contains_expr l (IL1_EIf e1 e2 e3) = contains_expr l e1 \/ contains_expr l e2 \/ contains_expr l e3)`;

val contains_def = Define `
    (contains l (IL1_Expr e) = contains_expr l e) /\
    (contains l1 (IL1_Assign l2 e) = (l1 = l2) \/ contains_expr l1 e) /\
    (contains l (IL1_Seq e1 e2) = contains l e1 \/ contains l e2) /\
    (contains l (IL1_SIf e1 e2 e3) = contains_expr l e1 \/ contains l e2 \/ contains l e3) /\
    (contains l (IL1_While e1 e2) = contains_expr l e1 \/ contains l e2)`;

val contains_a_def = Define `
    (contains_a l (IL1_Expr _) = F) /\
    (contains_a l1 (IL1_Assign l2 e) = (l1 = l2)) /\
    (contains_a l (IL1_Seq e1 e2) = contains_a l e1 \/ contains_a l e2) /\
    (contains_a l (IL1_SIf _ e2 e3) = contains_a l e2 \/ contains_a l e3) /\
    (contains_a l (IL1_While _ e2) = contains_a l e2)`;

val CONTAINS_A_SUB = store_thm("CONTAINS_A_SUB",
``!l e.contains_a l e ==> contains l e``,
Induct_on `e` THEN metis_tac [contains_a_def, contains_def]);


val WHILE_UNWIND_ONCE_THM = store_thm("WHILE_UNWIND_ONCE_THM",
``!e1 s e2 v s'.bs_il1_expr (e1, s) (IL1_Boolean T) ==> (bs_il1 (IL1_While e1 e2, s) IL1_ESkip s' <=> bs_il1 (IL1_Seq e2 (IL1_While e1 e2), s) IL1_ESkip s')``,
rw [EQ_IMP_THM] THEN1
(imp_res_tac IL1_WHILE_BACK_THM
THEN1 (imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [])
THEN1 (rw [Once bs_il1_cases] THEN metis_tac []))
THEN1 (rw [Once bs_il1_cases] THEN imp_res_tac IL1_SEQ_BACK_THM THEN metis_tac [IL1_SEQ_BACK_THM])
);

val l1_to_il1_pair_def = Define `
    (l1_to_il1_pair lc (B_Value (B_N n)) = (IL1_Expr (IL1_Value IL1_ESkip), IL1_Value (IL1_Integer n), lc)) /\
    (l1_to_il1_pair lc (B_Value (B_B b)) = (IL1_Expr (IL1_Value IL1_ESkip), IL1_Value (IL1_Boolean b), lc)) /\
    (l1_to_il1_pair lc (B_Value B_Skip) = (IL1_Expr (IL1_Value IL1_ESkip), IL1_Value IL1_ESkip, lc)) /\
    (l1_to_il1_pair lc (B_Deref l) = (IL1_Expr (IL1_Value IL1_ESkip), IL1_Deref (User l), lc)) /\

    (l1_to_il1_pair lc (B_Assign l e) =
        let (sl, e', lc2) = l1_to_il1_pair lc e
        in
            (IL1_Seq sl (IL1_Assign (User l) e'), IL1_Value IL1_ESkip,lc2)) /\

    (l1_to_il1_pair lc (B_Seq e1 e2) =
        let (sl1, e1', lc2) = l1_to_il1_pair lc e1 in
        let (sl2, e2', lc3) = l1_to_il1_pair lc2 e2
        in (IL1_Seq (IL1_Seq sl1 (IL1_Expr e1')) sl2, e2', lc3)) /\

    (l1_to_il1_pair lc (B_While e1 e2) =
        let (sl1, e1', lc2) = l1_to_il1_pair lc e1 in
        let (sl2, e2', lc3) = l1_to_il1_pair lc2 e2
        in
            (IL1_Seq sl1 (IL1_While e1' (IL1_Seq sl2 sl1)), IL1_Value IL1_ESkip, lc3)) /\

    (l1_to_il1_pair lc (B_If e1 e2 e3) =
        let (sl1, e1', lc2) = l1_to_il1_pair lc e1 in 
        let (sl2, e2', lc3) = l1_to_il1_pair lc2 e2 in
        let (sl3, e3', lc4) = l1_to_il1_pair lc3 e3
        in
            (IL1_Seq
                (IL1_Seq sl1
                    (IL1_Assign (Compiler lc4) (IL1_EIf e1' (IL1_Value (IL1_Integer 1)) (IL1_Value (IL1_Integer 0)))))
                (IL1_SIf e1' sl2 sl3),
             IL1_EIf (IL1_Geq (IL1_Deref (Compiler lc4)) (IL1_Value (IL1_Integer 1))) e2' e3',
             lc4 + 1)) /\

    (l1_to_il1_pair lc (B_Plus e1 e2) =
        let (sl1, e1', lc2) = l1_to_il1_pair lc e1 in
        let (sl2, e2', lc3) = l1_to_il1_pair lc2 e2
        in
            (IL1_Seq (IL1_Seq sl1 (IL1_Assign (Compiler lc3) e1')) sl2, IL1_Plus (IL1_Deref (Compiler lc3)) e2', lc3 + 1)) /\ 

    (l1_to_il1_pair lc (B_Geq e1 e2) =
        let (sl1, e1', lc2) = l1_to_il1_pair lc e1 in
        let (sl2, e2', lc3) = l1_to_il1_pair lc2 e2
        in
            (IL1_Seq (IL1_Seq sl1 (IL1_Assign (Compiler lc3) e1')) sl2, IL1_Geq (IL1_Deref (Compiler lc3)) e2', lc3 + 1))
`;

val l1_to_il1_def = Define `l1_to_il1 e n = let (s, te, lc) = l1_to_il1_pair n e in IL1_Seq s (IL1_Expr te)`;

val l1_il1_val_def = Define `(l1_il1_val (B_N n) = IL1_Integer n) /\
(l1_il1_val (B_B b) = IL1_Boolean b) /\
(l1_il1_val (B_Skip) = IL1_ESkip)`;

val il1_l1_val_def = Define `(il1_l1_val (IL1_Integer n) = B_N n) /\
(il1_l1_val (IL1_Boolean b) = B_B b) /\
(il1_l1_val IL1_ESkip = B_Skip)`;

val equiv_def = Define `equiv s1 s2 = !k.(User k ∈ FDOM s1 <=> User k ∈ FDOM s2) /\ (s1 ' (User k) = s2 ' (User k))`;

val EQUIV_REFL_THM = store_thm("EQUIV_REFL_THM",
``!x.equiv x x``,
fs [equiv_def]);

val EQUIV_TRANS_THM = store_thm("EQUIV_TRANS_THM",
``!x y z.equiv x y /\ equiv y z ==> equiv x z``,
rw [equiv_def]);

val EQUIV_APPEND_THM = store_thm("EQUIV_APPEND_THM",
``!e1 e2 k v.equiv e1 e2 ==> equiv (e1 |+ (k, v)) (e2 |+ (k, v))``,
rw [equiv_def] THEN metis_tac [FST, FUPDATE_SAME_APPLY]);

val MAP_APPEND_EQUIV_THM = store_thm("MAP_APPEND_EQUIV_THM",
``!s k v.(MAP_KEYS User s) |+ (User k, v) = (MAP_KEYS User (s |+ (k, v)))``,
rw [] THEN `INJ User (k INSERT FDOM s) UNIV` by rw [INJ_DEF]
THEN metis_tac [MAP_KEYS_FUPDATE])

val EQUIV_SYM_THM = store_thm("EQUIV_SYM_THM",
``!s s'.equiv s s' <=> equiv s' s``,
metis_tac [equiv_def]);

val STORE_L1_IL1_INJ = store_thm("STORE_L1_IL1_INJ",
``!l s. l ∈ FDOM s ==> ((s ' l) = (MAP_KEYS User s) ' (User l))``,
rw [] THEN `FDOM (MAP_KEYS User s) = IMAGE User (FDOM s)` by rw [FDOM_DEF, MAP_KEYS_def, IMAGE_DEF]
THEN `INJ User (FDOM s) UNIV` by rw [INJ_DEF] THEN metis_tac [MAP_KEYS_def]);

val BS_VALUE_THM = store_thm("BS_VALUE_THM",
``!v v' s.bs_il1_expr (IL1_Value v, s) v' ==> (v = v') /\ !s'.bs_il1_expr (IL1_Value v, s') v'``,
Cases_on `v` THEN REPEAT (rw [Once bs_il1_expr_cases]));


val con_store_def = Define `con_store s = MAP_KEYS User s`;

val NOT_CONTAINS_MEANS_UNCHANGED_LEMMA = store_thm("NOT_CONTAINS_MEANS_UNCHANGED_LEMMA",
``!p v s'.bs_il1 p v s' ==> !l.~contains_a l (FST p) ==> (((SND p) ' l) = (s' ' l))``,
ho_match_mp_tac (fetch "il1" "bs_il1_strongind") THEN rw [FST, SND] THEN fs [contains_a_def] THEN metis_tac [FAPPLY_FUPDATE_THM]);

val NOT_CONTAINS_MEANS_UNCHANGED_THM = store_thm("NOT_CONTAINS_MEANS_UNCHANGED_THM",
``!e s v s'.bs_il1 (e, s) v s' ==> !l.~contains_a l e ==> (s ' l = s' ' l)``,
metis_tac [NOT_CONTAINS_MEANS_UNCHANGED_LEMMA, FST, SND]);

val CONTAINS_SIMPED_THM = store_thm("CONTAINS_SIMPED_THM",
``!n e st ex n' l.(l1_to_il1_pair n e = (st, ex, n')) ==> (contains_a l (l1_to_il1 e n) <=> contains_a l st)``,
rw [EQ_IMP_THM]
THEN1 (fs [l1_to_il1_def]
THEN `contains_a l (let (s, te, lc) = (st, ex, n') in IL1_Seq s (IL1_Expr te))` by metis_tac []
THEN fs [LET_DEF, contains_a_def])
THEN rw [l1_to_il1_def] THEN rw [contains_a_def]
);

val MAP_FDOM_AFTER_INSERT = store_thm("MAP_FDOM_AFTER_INSERT",
``!f a b.a ∈ FDOM (f |+ (a, b))``,
rw [FDOM_DEF]);

val ASSIGN_ENSURES_IN_DOM_THM = store_thm("ASSIGN_ENSURES_IN_DOM_THM",
``!l e s s'.bs_il1 (IL1_Assign l e, s) IL1_ESkip s' ==> l ∈ FDOM s'``,
rw [Once bs_il1_cases] THEN rw [FDOM_DEF]);

val minimal_store_def = Define `minimal_store e s = !k.k ∈ FDOM s ==> contains_l1 k e`;

val count_assign_def = Define `
(count_assign (IL1_Expr _) _ = Num 0) /\
(count_assign (IL1_SIf _ e2 e3) l = count_assign e2 l + count_assign e3 l) /\
(count_assign (IL1_While _ e2) l = count_assign e2 l) /\
(count_assign (IL1_Assign l1 e) l2 = if l1 = l2 then Num 1 else Num 0) /\
(count_assign (IL1_Seq e1 e2) l = count_assign e1 l + count_assign e2 l)`;

val count_deref_expr_def = Define `
(count_deref_expr (IL1_Deref l) l' = if l = l' then Num 1 else Num 0) /\
(count_deref_expr (IL1_Value _) _ = Num 0) /\
(count_deref_expr (IL1_Plus e1 e2) l = count_deref_expr e1 l + count_deref_expr e2 l) /\
(count_deref_expr (IL1_Geq e1 e2) l = count_deref_expr e1 l + count_deref_expr e2 l) /\
(count_deref_expr (IL1_EIf e1 e2 e3) l = count_deref_expr e1 l + count_deref_expr e2 l + count_deref_expr e3 l)`;

val count_deref_def = Define `
(count_deref (IL1_Expr e) l = count_deref_expr e l) /\
(count_deref (IL1_SIf e1 e2 e3) l = count_deref_expr e1 l + count_deref e2 l + count_deref e3 l) /\
(count_deref (IL1_While e1 e2) l = count_deref_expr e1 l + count_deref e2 l) /\
(count_deref (IL1_Assign l1 e) l2 = count_deref_expr e l2) /\
(count_deref (IL1_Seq e1 e2) l = count_deref e1 l + count_deref e2 l)`;

val DOMS_SUBSET_THM_1 = store_thm("DOMS_SUBSET_THM",
``!p v s'.bs_il1 p v s' ==> FDOM (SND p) ⊆ FDOM s'``,
ho_match_mp_tac (fetch "il1" "bs_il1_strongind") THEN rw [FST, SND, SUBSET_DEF]);

val DOMS_SUBSET_THM = store_thm("DOMS_SUBSET_THM",
``!e s v s'.bs_il1 (e, s) v s' ==> FDOM s ⊆ FDOM s'``,
metis_tac [FST, SND, DOMS_SUBSET_THM_1]);

val bs_il1_cases = (fetch "il1" "bs_il1_cases");
val bs_il1_expr_cases = (fetch "il1" "bs_il1_expr_cases");

val NO_INTERMEDIATE_WRITES_SAME_VALUE = store_thm("NO_INTERMEDIATE_WRITES_SAME_VALUE",
``!p v.bs_il1_expr p v ==> !s' s'' l.l ∈ FDOM s'' ==> bs_il1 (IL1_Assign l (FST p), (SND p)) IL1_ESkip s' ==> ((s' ' l) = (s'' ' l)) ==> bs_il1_expr (IL1_Deref l, s'') v``,
Cases_on `p` THEN rw [FST, SND]
THEN fs [Once bs_il1_cases]
THEN rw [Once bs_il1_expr_cases]
THEN metis_tac [(fetch "il1" "BS_IL1_EXPR_DETERMINACY"), FAPPLY_FUPDATE]);

val L1_TO_IL1_TOTAL_THM = store_thm("L1_TO_IL1_TOTAL_THM",
``!e n.?sl e' lc.l1_to_il1_pair n e = (sl, e', lc)``,
Induct_on `e` THEN rw [l1_to_il1_pair_def]
THEN TRY (Cases_on `b` THEN EVAL_TAC THEN metis_tac []) THEN
TRY (`?sl e' lc.l1_to_il1_pair n e = (sl, e', lc)` by METIS_TAC [] THEN
`?sl e'' lc'.l1_to_il1_pair lc e' = (sl, e'', lc')` by METIS_TAC [] THEN
rw [] THEN `?sl e''' lc''.l1_to_il1_pair lc' e'' = (sl, e''', lc'')` by METIS_TAC [] THEN rw [])
THEN TRY (`?sl e' lc.l1_to_il1_pair n' e = (sl, e', lc)` by metis_tac [] THEN rw [] THEN FAIL_TAC "since nothing else will")
THEN
`?sl e' lc.l1_to_il1_pair n e = (sl, e', lc)` by METIS_TAC [] THEN
`?sl e'' lc'.l1_to_il1_pair lc e' = (sl, e'', lc')` by METIS_TAC [] THEN
`?sl e''' lc''.l1_to_il1_pair lc' e = (sl, e''', lc'')` by METIS_TAC []
THEN rw []);

val SKIP_TO_SKIP_THM = store_thm("SKIP_TO_SKIP",
``!s.bs_il1_expr (IL1_Value IL1_ESkip, s) IL1_ESkip``,
rw [Once bs_il1_expr_cases] THEN metis_tac []);

val SKIP_TO_SKIP_2_THM = store_thm("SKIP_TO_SKIP_2_THM",
``!s.bs_il1 (IL1_Expr (IL1_Value IL1_ESkip), s) IL1_ESkip s``,
rw [Once bs_il1_cases, Once bs_il1_expr_cases] THEN metis_tac []);

val ASSIGN_IMPLIES_SKIP_THM = store_thm("ASSIGN_IMPLIES_SKIP_THM",
``!e lc s st ex l lc'.(l1_to_il1_pair lc (B_Assign l e) = (st, ex, lc')) ==> (ex = IL1_Value (IL1_ESkip))``,
rw [l1_to_il1_pair_def]
THEN `?sl1 e1' lc2'.l1_to_il1_pair lc e = (sl1, e1', lc2')` by metis_tac [L1_TO_IL1_TOTAL_THM] 
THEN fs [LET_DEF]);

val COMP_LOC_INCREASING_THM = store_thm("COMP_LOC_INCREASING_THM",
``!e n n' sl1 e1'.(l1_to_il1_pair n e = (sl1, e1', n')) ==> (n' >= n)``,
Induct_on `e` THEN rw []
THEN1 (Cases_on `b` THEN fs [l1_to_il1_pair_def] THEN EVAL_TAC)
THEN TRY (`?sl1 e1' lc2.l1_to_il1_pair n e = (sl1, e1', lc2)` by metis_tac [L1_TO_IL1_TOTAL_THM] THEN
`?sl2 e2' lc3.l1_to_il1_pair lc2 e' = (sl2, e2', lc3)` by metis_tac [L1_TO_IL1_TOTAL_THM] THEN
`?sl3 e3' lc4.l1_to_il1_pair lc3 e'' = (sl3, e3', lc4)` by metis_tac [L1_TO_IL1_TOTAL_THM] THEN
fs [LET_DEF, l1_to_il1_pair_def] THEN
res_tac THEN
decide_tac)
THEN1 ((`?sl1 e1' n''.l1_to_il1_pair n' e = (sl1, e1', n'')` by metis_tac [L1_TO_IL1_TOTAL_THM]) THEN fs [l1_to_il1_pair_def, LET_DEF])
);

val CONTAINS_CONVERT_THM = store_thm("CONTAINS_CONVERT_THM",
``!e n l.contains l (l1_to_il1 e n) <=> ?st ex n'.(l1_to_il1_pair n e = (st, ex, n')) /\ (contains l st \/ contains_expr l ex)``,
rw [EQ_IMP_THM] THEN1 (`?st ex n'.l1_to_il1_pair n e = (st, ex, n')` by metis_tac [L1_TO_IL1_TOTAL_THM] THEN fs [l1_to_il1_def, LET_DEF, contains_def]) THEN rw [l1_to_il1_def, LET_DEF, contains_def]);

val COMPILER_LOC_CHANGE_THM = store_thm("COMPILER_LOC_CHANGE_THM",
``!st ex n n' e.(l1_to_il1_pair n e = (st, ex, n')) ==> (n <> n') ==> contains_a (Compiler n) (l1_to_il1 e n)``,
Induct_on `e` THEN rw []

THEN1 (Cases_on `b` THEN fs [l1_to_il1_def, l1_to_il1_pair_def, contains_a_def])

THEN TRY (`?st ex rl.l1_to_il1_pair n e = (st, ex, rl)` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st' ex' rl'.l1_to_il1_pair rl e' = (st', ex', rl')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st'' ex'' rl''.l1_to_il1_pair rl' e'' = (st'', ex'', rl'')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN fs [LET_DEF, l1_to_il1_def, l1_to_il1_pair_def]
THEN rw []
THEN imp_res_tac COMP_LOC_INCREASING_THM
THEN rw [contains_a_def]
THEN res_tac

THEN Cases_on `n = rl`
THEN Cases_on `rl = rl'`
THEN Cases_on `rl' = rl''`
THEN fs [contains_a_def]
THEN FAIL_TAC "expect to fail")

THEN1 (`?st ex rl.l1_to_il1_pair n' e = (st, ex, rl)` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN fs [LET_DEF, l1_to_il1_def, l1_to_il1_pair_def]
THEN rw []
THEN fs [contains_a_def]));

val ALL_CO_LOCS_IN_RANGE_BA = store_thm("ALL_CO_LOCS_IN_RANGE_BA",
``!e n st ex n' tn.(l1_to_il1_pair n e = (st, ex, n')) ==> contains (Compiler tn) (l1_to_il1 e n) ==> (tn >= n) /\ (tn < n')``,
Induct_on `e` THEN rw []

(* Base cases *)
THEN1 (Cases_on `b` THEN fs [l1_to_il1_def, l1_to_il1_pair_def, LET_DEF, contains_def, contains_expr_def] THEN rw [])
THEN1 (Cases_on `b` THEN fs [l1_to_il1_def, l1_to_il1_pair_def, LET_DEF, contains_def, contains_expr_def] THEN rw [])
(* end base cases *)

(* Most cases *)
THEN TRY (`?st ex rl.l1_to_il1_pair n e = (st, ex, rl)` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st' ex' rl'.l1_to_il1_pair rl e' = (st', ex', rl')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st'' ex'' rl''.l1_to_il1_pair rl' e'' = (st'', ex'', rl'')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st'' ex'' rl''.l1_to_il1_pair rl' e = (st'', ex'', rl'')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN fs [l1_to_il1_def, l1_to_il1_pair_def, LET_DEF, contains_def, contains_expr_def] THEN rw [] THEN imp_res_tac COMP_LOC_INCREASING_THM THEN res_tac THEN decide_tac)
THEN `?st ex rl.l1_to_il1_pair n' e = (st, ex, rl)` by metis_tac [L1_TO_IL1_TOTAL_THM] THEN fs [l1_to_il1_def, l1_to_il1_pair_def, LET_DEF, contains_def, contains_expr_def] THEN rw [] THEN imp_res_tac COMP_LOC_INCREASING_THM THEN res_tac THEN decide_tac);

val ALL_CO_LOCS_IN_RANGE_FOR = store_thm("ALL_CO_LOCS_IN_RANGE_FOR",
``!e n st ex n'.(l1_to_il1_pair n e = (st, ex, n')) ==> !n''.(n'' >= n) /\ (n'' < n') ==> contains_a (Compiler n'') (l1_to_il1 e n)``,
Induct_on `e` THEN rw []

THEN1 (Cases_on `b` THEN fs [l1_to_il1_pair_def] THEN rw [] THEN decide_tac)

THEN `?st ex rl.l1_to_il1_pair n e = (st, ex, rl)` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st' ex' rl'.l1_to_il1_pair rl e' = (st', ex', rl')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st'' ex'' rl''.l1_to_il1_pair rl' e'' = (st'', ex'', rl'')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st ex rl.l1_to_il1_pair n' e = (st, ex, rl)` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN fs [LET_DEF, l1_to_il1_def, l1_to_il1_pair_def] THEN rw []
THEN fs [contains_a_def]
THEN res_tac

THEN TRY (
Cases_on `n'' < rl` THEN fs [contains_a_def] THEN rw []
THEN fs [NOT_LESS]
THEN Cases_on `n'' = rl'` THEN rw []
THEN `n'' < rl'` by decide_tac
THEN res_tac
THEN fs [GREATER_EQ]
THEN FAIL_TAC "want to fail")

THEN1 (
Cases_on `n'' < rl` THEN fs [contains_a_def] THEN rw []
THEN fs [NOT_LESS]
THEN Cases_on `n'' = rl''` THEN rw []
THEN `n'' < rl''` by decide_tac
THEN fs [GREATER_EQ]
THEN res_tac
THEN `rl'' >= rl'` by metis_tac [COMP_LOC_INCREASING_THM]
THEN fs [GREATER_EQ]
THEN rw []
THEN Cases_on `rl' <= n''` THEN fs [NOT_LESS_EQUAL])

THEN1 (
decide_tac
)

THEN1 (
Cases_on `n'' < rl` THEN fs [contains_a_def] THEN rw []
THEN fs [NOT_LESS, GREATER_EQ])

THEN (
Cases_on `n'' < rl` THEN fs [contains_a_def] THEN rw []
THEN fs [NOT_LESS]
THEN Cases_on `n'' = rl''` THEN rw []
THEN `n'' < n'` by decide_tac
THEN metis_tac [COMP_LOC_INCREASING_THM, GREATER_EQ, NOT_LESS_EQUAL]));

val CONTAINS_IMPLIES_COUNT_NZERO = store_thm("CONTAINS_IMPLIES_COUNT_NZERO",
``!e l.contains_a l e <=> (count_assign e l <> 0)``,
rw [EQ_IMP_THM] THEN Induct_on `e` THEN rw [contains_a_def, count_assign_def] THEN metis_tac []);

val ALL_CO_LOCS_IN_RANGE = store_thm("ALL_CO_LOCS_IN_RANGE",
``!e n st ex n' tn.(l1_to_il1_pair n e = (st, ex, n')) ==> (contains (Compiler tn) (l1_to_il1 e n) <=> (tn >= n) /\ (tn < n'))``,
metis_tac [EQ_IMP_THM, ALL_CO_LOCS_IN_RANGE_BA, ALL_CO_LOCS_IN_RANGE_FOR, CONTAINS_A_SUB]);

val UNCHANGED_LOC_SIMP_THM = store_thm("UNCHANGED_LOC_SIMP_THM",
``!n e st ex n' tn.(l1_to_il1_pair n e = (st,ex,n')) ⇒
     (contains_a (Compiler tn) st ⇔ tn ≥ n ∧ tn < n')``,
rw [EQ_IMP_THM] THEN metis_tac [CONTAINS_SIMPED_THM, ALL_CO_LOCS_IN_RANGE_BA, (fetch "il1" "CONTAINS_A_SUB"), ALL_CO_LOCS_IN_RANGE_FOR]);

val MAX_LOC_MIN_STORE_THM = store_thm("MAX_LOC_MIN_STORE_THM",
``!e s.minimal_store e s ==> !k.k ∈ FDOM s ==> k <= max_loc_l1 e``,
rw [minimal_store_def] THEN
`contains_l1 k e` by fs [] THEN
CCONTR_TAC THEN
fs [NOT_LESS_EQUAL, (fetch "l1" "UNUSED_UPPER_LOCS_THM")]);

val B_USELESS_LOC_EXPR_THM = store_thm("B_USELESS_LOC_EXPR_THM",
``!p r.bs_il1_expr p r ==> !k.~contains_expr k (FST p) ==> !v.bs_il1_expr (FST p, SND p |+ (k, v)) r``,
HO_MATCH_MP_TAC (fetch "il1" "bs_il1_expr_strongind") THEN rw []
THEN1 (Cases_on `r` THEN fs [Once (fetch "il1" "bs_il1_expr_cases")]) THEN TRY (
rw [Once (fetch "il1" "bs_il1_expr_cases")]
THEN fs [contains_expr_def] THEN metis_tac [])
THEN fs [contains_expr_def]
THEN rw [Once (fetch "il1" "bs_il1_expr_cases"), NOT_EQ_FAPPLY]);

val USELESS_LOC_EXPR_THM = store_thm("USELESS_LOC_EXPR_THM",
``!e s r.bs_il1_expr (e, s) r ==> !k.~contains_expr k e ==> !v.bs_il1_expr (e, s |+ (k, v)) r``,
METIS_TAC [B_USELESS_LOC_EXPR_THM, FST, SND]);


val B_USELESS_LOC_THM = store_thm("B_USELESS_LOC_THM",
``!p r s'.bs_il1 p r s' ==> !k.~contains k (FST p) ==> !v.bs_il1 (FST p, SND p |+ (k, v)) r (s' |+ (k, v))``,
HO_MATCH_MP_TAC (fetch "il1" "bs_il1_strongind") THEN rw []
THEN1 (fs [Once (fetch "il1" "bs_il1_cases"), contains_def] THEN METIS_TAC [USELESS_LOC_EXPR_THM])
THEN rw [Once (fetch "il1" "bs_il1_cases")] THEN fs [contains_def, FUPDATE_COMMUTES] THEN METIS_TAC [USELESS_LOC_EXPR_THM]);

val USELESS_LOC_THM = store_thm("USELESS_LOC_THM",
``!e s r s'.bs_il1 (e, s) r s' ==> !k.~contains k e ==> !v.bs_il1 (e, s |+ (k, v)) r (s' |+ (k, v))``,
METIS_TAC [FST, SND, B_USELESS_LOC_THM]);

val IL1_SEQ_ASSOC_THM = store_thm("IL1_SEQ_ASSOC_THM",
``!e1 e2 e3 s v s'.bs_il1 (IL1_Seq e1 (IL1_Seq e2 e3), s) v s' <=> bs_il1 (IL1_Seq (IL1_Seq e1 e2) e3, s) v s'``,
rw [EQ_IMP_THM]
THEN1 (fs [Once (fetch "il1" "bs_il1_cases")] THEN rw [Once (fetch "il1" "bs_il1_cases")] THEN metis_tac [IL1_SEQ_BACK_THM])
THEN1 (rw [Once (fetch "il1" "bs_il1_cases")] THEN imp_res_tac IL1_SEQ_BACK_THM THEN imp_res_tac IL1_SEQ_BACK_THM THEN metis_tac [(fetch "il1" "bs_il1_cases")]));


val EXPR_PURE_THM = store_thm("EXPR_DOES_NOTHING_THM",
``!st es s s' v.bs_il1 (IL1_Seq st (IL1_Expr es), s) v s' ==> bs_il1 (st, s) IL1_ESkip s'``,
rw [] THEN
`bs_il1 (st, s) IL1_ESkip s' /\ bs_il1 (IL1_Expr es, s') v s'` by ALL_TAC THEN
IMP_RES_TAC IL1_SEQ_BACK_THM THEN
`s'' = s'` by fs [Once (fetch "il1" "bs_il1_cases")] THEN
metis_tac []);

val EXPR_PURE_2_THM = store_thm("EXPR_PURE_2_THM",
``!e s v s'.bs_il1 (IL1_Expr e, s) v s' ==> (s = s')``,
rw [Once (fetch "il1" "bs_il1_cases")]);

val plus_case = (* Begin plus case *)
(fs [l1_to_il1_pair_def, l1_il1_val_def]

THEN `?st1 ex1 lc1''.l1_to_il1_pair lc1 e1 = (st1, ex1, lc1'')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN `?st2 ex2 lc2''.l1_to_il1_pair lc1'' e2 = (st2, ex2, lc2'')` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN fs [LET_DEF] THEN rw []

THEN rw [Once bs_il1_cases]
THEN rw [Once bs_il1_cases]


THEN `?fs'.bs_il1 (st1, fs) IL1_ESkip fs' /\ bs_il1_expr (ex1, fs') (IL1_Integer n1) /\ equiv (con_store s') fs'` by metis_tac []
THEN `bs_il1 (IL1_Assign (Compiler lc2'') ex1, fs') IL1_ESkip (fs' |+ (Compiler lc2'', n1))` by (rw [Once bs_il1_cases] THEN metis_tac [])

THEN `equiv fs' (fs' |+ (Compiler lc2'', n1))` by (rw [equiv_def] THEN `Compiler lc2'' <> User k` by rw [] THEN metis_tac [FAPPLY_FUPDATE_THM])
THEN `equiv (con_store s') (fs' |+ (Compiler lc2'', n1))` by metis_tac [EQUIV_TRANS_THM]


THEN `?fs''.bs_il1 (st2, fs' |+ (Compiler lc2'', n1)) IL1_ESkip fs'' /\ bs_il1_expr (ex2, fs'') (IL1_Integer n2) /\ equiv (con_store s'') fs''` by metis_tac []

THEN `(fs' |+ (Compiler lc2'',n1)) ' (Compiler lc2'') = fs'' ' (Compiler lc2'')` by (`~contains_a (Compiler lc2'') st2` by (CCONTR_TAC THEN fs[] THEN imp_res_tac UNCHANGED_LOC_SIMP_THM THEN decide_tac) THEN metis_tac [NOT_CONTAINS_MEANS_UNCHANGED_THM])

THEN `bs_il1_expr (IL1_Deref (Compiler lc2''), fs'') (IL1_Integer n1)` by (rw [Once bs_il1_expr_cases] THEN metis_tac [SUBSET_DEF, FAPPLY_FUPDATE, MAP_FDOM_AFTER_INSERT, DOMS_SUBSET_THM])

THEN rw [Once bs_il1_expr_cases]
THEN metis_tac []);
(* End plus case *)

val IL1_SEQ_FOR_THM = store_thm("IL1_SEQ_FOR_THM",
``!e1 e2 s s' s'' v.bs_il1 (e1, s) IL1_ESkip s' /\ bs_il1 (e2, s') v s'' ==> bs_il1 (IL1_Seq e1 e2, s) v s''``,
metis_tac [bs_il1_cases]);

val IL1_EXPR_FOR_THM = store_thm("IL1_EXPR_FOR_THM",
``!e s v.bs_il1_expr (e, s) v ==> bs_il1 (IL1_Expr e, s) v s``,
metis_tac [bs_il1_cases]);

val total = metis_tac [L1_TO_IL1_TOTAL_THM];

val L1_TO_IL1_CORRECTNESS_LEMMA = store_thm("L1_TO_IL1_CORRECTNESS_LEMMA",
``!p v s'.big_step p v s' ==> !lc1 st ex lc1'.((st, ex, lc1') = l1_to_il1_pair lc1 (FST p)) ==> !fs.equiv (con_store (SND p)) fs ==> ?fs'.bs_il1 (st, fs) IL1_ESkip fs' /\ bs_il1_expr (ex, fs') (l1_il1_val v) /\ equiv (con_store s') fs'``,
ho_match_mp_tac (fetch "l1" "big_step_strongind") THEN rw [FST, SND]

(* Begin unit case *)

THEN1 (Cases_on `v` THEN rw [l1_il1_val_def] THEN fs [l1_to_il1_pair_def] THEN rw []
THEN rw [Once bs_il1_cases, Once bs_il1_expr_cases] THEN rw [Once bs_il1_cases, Once bs_il1_expr_cases])

(* End unit cases *)

THEN1 plus_case
THEN1 plus_case

(* Dereference case *)
THEN1 (fs [l1_to_il1_pair_def, l1_il1_val_def] THEN rw [Once bs_il1_cases]

THEN1 metis_tac [SKIP_TO_SKIP_THM]
THEN fs [Once bs_il1_expr_cases, equiv_def, con_store_def, MAP_KEYS_def, STORE_L1_IL1_INJ])
(* End dereference case *)

(* Begin assign case *)
THEN1 (fs [l1_to_il1_pair_def, l1_il1_val_def] THEN rw []
THEN `?st1 ex1 lc1''.l1_to_il1_pair lc1 e = (st1, ex1, lc1'')` by total
THEN fs [LET_DEF] THEN rw []

THEN rw [Once bs_il1_expr_cases]
THEN `?fs'.bs_il1 (st1,fs) IL1_ESkip fs' /\ bs_il1_expr (ex1, fs') (IL1_Integer n) /\ equiv (con_store s') fs'` by metis_tac []

THEN `bs_il1 (IL1_Assign (User l) ex1, fs') IL1_ESkip (fs' |+ (User l, n))` by (rw [Once bs_il1_cases] THEN
`User l ∈ FDOM (con_store s)` by rw [FDOM_DEF, con_store_def, MAP_KEYS_def] THEN
`User l ∈ FDOM fs` by metis_tac [equiv_def] THEN
metis_tac [SUBSET_DEF, DOMS_SUBSET_THM])

THEN rw [con_store_def]

THEN `equiv (MAP_KEYS User (s' |+ (l, n))) (fs' |+ (User l, n))` by (fs [con_store_def] THEN `equiv (MAP_KEYS User s' |+ (User l, n)) (fs' |+ (User l, n))` by metis_tac [EQUIV_APPEND_THM] THEN metis_tac [con_store_def, MAP_APPEND_EQUIV_THM, EQUIV_APPEND_THM])
THEN rw [Once bs_il1_cases]
THEN metis_tac [con_store_def])
(* End assign case *)

THEN fs [l1_to_il1_pair_def, l1_il1_val_def]
THEN `?st1 ex1 lc1''.l1_to_il1_pair lc1 e1 = (st1, ex1, lc1'')` by total
THEN `?st2 ex2 lc2''.l1_to_il1_pair lc1'' e2 = (st2, ex2, lc2'')` by total
THEN `?st3 ex3 lc3''.l1_to_il1_pair lc2'' e3 = (st3, ex3, lc3'')` by total
THEN res_tac
THEN fs [LET_DEF] THEN rw []

(* Begin seq case *)
THEN1 (rw [Once bs_il1_cases]
THEN rw [Once bs_il1_cases]

THEN imp_res_tac EQ_SYM

THEN res_tac

THEN `bs_il1 (IL1_Expr ex1, fs'') (IL1_ESkip) fs''` by (rw [Once bs_il1_cases])
THEN metis_tac [])
(* End seq case *)

(* Start if true case *)

THEN1 (
rw [Once bs_il1_cases]
THEN rw [Once bs_il1_cases]


THEN `?fs'.bs_il1 (st1, fs) IL1_ESkip fs' /\ bs_il1_expr (ex1, fs') (IL1_Boolean T) /\ equiv (con_store s') fs'` by metis_tac []


THEN   `bs_il1
          (IL1_Assign (Compiler lc3'')
             (IL1_EIf ex1 (IL1_Value (IL1_Integer 1))
                (IL1_Value (IL1_Integer 0))),fs') IL1_ESkip (fs' |+ (Compiler lc3'', 1))` by (rw [Once bs_il1_cases]
THEN rw [Once bs_il1_expr_cases]
THEN rw [Once bs_il1_expr_cases]
THEN metis_tac [])

THEN `equiv fs' (fs' |+ (Compiler lc3'', 1))` by (rw [equiv_def] THEN `Compiler lc3'' <> User k` by rw [] THEN metis_tac [FAPPLY_FUPDATE_THM])
THEN `equiv (con_store s') (fs' |+ (Compiler lc3'', 1))` by metis_tac [EQUIV_TRANS_THM]

THEN `?fs''.bs_il1 (st2, fs' |+ (Compiler lc3'', 1)) IL1_ESkip fs'' /\ bs_il1_expr (ex2, fs'') (l1_il1_val v) /\ equiv (con_store s'') fs''` by metis_tac []


THEN `bs_il1 (IL1_SIf ex1 st2 st3, fs' |+ (Compiler lc3'', 1)) IL1_ESkip fs''` by (rw [Once bs_il1_cases]


THEN `~contains (Compiler lc3'') (l1_to_il1 e1 lc1)` by (CCONTR_TAC THEN fs [] THEN imp_res_tac ALL_CO_LOCS_IN_RANGE THEN imp_res_tac COMP_LOC_INCREASING_THM THEN decide_tac)

THEN fs [contains_def, l1_to_il1_def] THEN rw []
THEN `~contains (Compiler lc3'') (let (s, te, lc) = (st1, ex1, lc1'') in IL1_Seq s (IL1_Expr te))` by metis_tac []
THEN fs [LET_DEF] THEN rw []
THEN fs [contains_def]
THEN metis_tac [USELESS_LOC_EXPR_THM])

(*    *)
THEN `bs_il1_expr
    (IL1_EIf
       (IL1_Geq (IL1_Deref (Compiler lc3''))
          (IL1_Value (IL1_Integer 1))) ex2 ex3,fs'') (l1_il1_val v) ∧
  equiv (con_store s'') fs''` by (
rw [Once bs_il1_expr_cases]
THEN rw [Once bs_il1_expr_cases]

THEN `bs_il1_expr (IL1_Deref (Compiler lc3''), fs'') (IL1_Integer 1)` by (

`(fs' |+ (Compiler lc3'', 1)) ' (Compiler lc3'') = fs'' ' (Compiler lc3'')` by (`~contains_a  (Compiler lc3'') st2` by (CCONTR_TAC THEN fs [] THEN imp_res_tac UNCHANGED_LOC_SIMP_THM THEN imp_res_tac COMP_LOC_INCREASING_THM THEN decide_tac) THEN metis_tac [NOT_CONTAINS_MEANS_UNCHANGED_THM])

THEN rw [Once bs_il1_expr_cases] THEN metis_tac [SUBSET_DEF, FAPPLY_FUPDATE, MAP_FDOM_AFTER_INSERT, DOMS_SUBSET_THM]




THEN metis_tac [])
THEN `bs_il1_expr (IL1_Value (IL1_Integer 1), fs'') (IL1_Integer 1)` by (rw [Once bs_il1_expr_cases] THEN metis_tac [])
THEN `1 >= 1` by metis_tac [int_ge, INT_LE_REFL]

THEN metis_tac [])

THEN metis_tac [])

(* End if true case *)

(* Start if false case *)

THEN1 (rw [Once bs_il1_cases]
THEN rw [Once bs_il1_cases]


THEN `?fs'.bs_il1 (st1, fs) IL1_ESkip fs' /\ bs_il1_expr (ex1, fs') (IL1_Boolean F) /\ equiv (con_store s') fs'` by metis_tac []


THEN   `bs_il1
          (IL1_Assign (Compiler lc3'')
             (IL1_EIf ex1 (IL1_Value (IL1_Integer 1))
                (IL1_Value (IL1_Integer 0))),fs') IL1_ESkip (fs' |+ (Compiler lc3'', 0))` by (rw [Once bs_il1_cases]
THEN rw [Once bs_il1_expr_cases]
THEN `bs_il1_expr (IL1_Value (IL1_Integer 0), fs') (IL1_Integer 0)` by (rw [Once bs_il1_expr_cases] THEN metis_tac [])
THEN metis_tac [])

THEN `equiv fs' (fs' |+ (Compiler lc3'', 0))` by (rw [equiv_def] THEN `Compiler lc3'' <> User k` by rw [] THEN metis_tac [FAPPLY_FUPDATE_THM])
THEN `equiv (con_store s') (fs' |+ (Compiler lc3'', 0))` by metis_tac [EQUIV_TRANS_THM]

THEN `?fs''.bs_il1 (st3, fs' |+ (Compiler lc3'', 0)) IL1_ESkip fs'' /\ bs_il1_expr (ex3, fs'') (l1_il1_val v) /\ equiv (con_store s'') fs''` by metis_tac []


THEN `bs_il1 (IL1_SIf ex1 st2 st3, fs' |+ (Compiler lc3'', 0)) IL1_ESkip fs''` by (rw [Once bs_il1_cases]


THEN `~contains (Compiler lc3'') (l1_to_il1 e1 lc1)` by (CCONTR_TAC THEN fs [] THEN imp_res_tac ALL_CO_LOCS_IN_RANGE THEN imp_res_tac COMP_LOC_INCREASING_THM THEN decide_tac)

THEN fs [contains_def, l1_to_il1_def] THEN rw []
THEN `~contains (Compiler lc3'') (let (s, te, lc) = (st1, ex1, lc1'') in IL1_Seq s (IL1_Expr te))` by metis_tac []
THEN fs [LET_DEF] THEN rw []
THEN fs [contains_def]
THEN metis_tac [USELESS_LOC_EXPR_THM])

(*    *)
THEN `bs_il1_expr
    (IL1_EIf
       (IL1_Geq (IL1_Deref (Compiler lc3''))
          (IL1_Value (IL1_Integer 1))) ex2 ex3,fs'') (l1_il1_val v) ∧
  equiv (con_store s'') fs''` by (
rw [Once bs_il1_expr_cases]
THEN rw [Once bs_il1_expr_cases]

THEN `bs_il1_expr (IL1_Deref (Compiler lc3''), fs'') (IL1_Integer 0)` by  (

`(fs' |+ (Compiler lc3'', 0)) ' (Compiler lc3'') = fs'' ' (Compiler lc3'')` by (`~contains_a  (Compiler lc3'') st3` by (CCONTR_TAC THEN fs [] THEN imp_res_tac UNCHANGED_LOC_SIMP_THM THEN imp_res_tac COMP_LOC_INCREASING_THM THEN decide_tac) THEN metis_tac [NOT_CONTAINS_MEANS_UNCHANGED_THM])

THEN rw [Once bs_il1_expr_cases] THEN metis_tac [SUBSET_DEF, FAPPLY_FUPDATE, MAP_FDOM_AFTER_INSERT, DOMS_SUBSET_THM])

THEN `bs_il1_expr
  (IL1_Geq (IL1_Deref (Compiler lc3'')) (IL1_Value (IL1_Integer 1)),
   fs'') (IL1_Boolean F)` by (
rw [Once bs_il1_expr_cases]
THEN `bs_il1_expr (IL1_Value (IL1_Integer 1), fs'') (IL1_Integer 1)` by (rw [Once bs_il1_expr_cases] THEN metis_tac [])
THEN `~(0 >= 1)` by metis_tac [int_ge, INT_NOT_LE, INT_LT_REFL, INT_LT_01, INT_LT_ANTISYM]


THEN metis_tac [])
THEN rw [Once bs_il1_expr_cases])
THEN metis_tac [])

(* end if false case *)

(* Begin while true case *)
THEN1 (

`?fs'.bs_il1 (st1,fs) IL1_ESkip fs' /\ bs_il1_expr (ex1, fs') (IL1_Boolean T) /\ equiv (con_store s') fs'` by metis_tac []
THEN `?fs''.bs_il1 (st2,fs') IL1_ESkip fs'' /\ bs_il1_expr (ex2, fs'') IL1_ESkip /\ equiv (con_store s'') fs''` by metis_tac []
THEN rw []
THEN res_tac

THEN fs [l1_il1_val_def]

THEN `bs_il1 (IL1_Seq st2 (IL1_Seq st1 (IL1_While ex1 (IL1_Seq st2 st1))), fs') IL1_ESkip fs'''` by (rw [Once bs_il1_cases] THEN metis_tac [])
THEN `bs_il1 (IL1_Seq (IL1_Seq st2 st1) (IL1_While ex1 (IL1_Seq st2 st1)), fs') IL1_ESkip fs'''` by metis_tac [IL1_SEQ_ASSOC_THM]
THEN `bs_il1 (IL1_While ex1 (IL1_Seq st2 st1), fs') IL1_ESkip fs'''` by metis_tac [WHILE_UNWIND_ONCE_THM]

THEN rw [Once bs_il1_cases]
THEN metis_tac [])
(*End while true case *)

(* Begin while false case *)
THEN1 (rw [Once bs_il1_cases]

THEN`?fs'.bs_il1 (st1, fs) IL1_ESkip fs' /\ bs_il1_expr (ex1, fs') (IL1_Boolean F) /\ equiv (con_store s') fs'` by metis_tac []

THEN fs [l1_il1_val_def]

THEN `bs_il1 (IL1_While ex1 (IL1_Seq st2 st1), fs') IL1_ESkip fs'` by (rw [Once bs_il1_cases] THEN metis_tac [])
THEN rw [Once bs_il1_expr_cases] THEN metis_tac [])
(* End while false case *));

val L1_TO_IL1_EXISTS_CORRECTNESS_THM = store_thm("L1_TO_IL1_EXISTS_CORRECTNESS_THM",
``!e s v s' s''.big_step (e, s) v s' ==> ?s''.bs_il1 (l1_to_il1 e 0, con_store s) (l1_il1_val v) s'' /\ equiv (con_store s') s''``,
rw [l1_to_il1_def]
THEN `?s''' te lc.l1_to_il1_pair 0 e = (s''', te, lc)` by total
THEN rw []
THEN `equiv (con_store s) (con_store s)` by metis_tac [EQUIV_REFL_THM]
THEN rw [Once bs_il1_cases]
THEN imp_res_tac EQ_SYM
THEN imp_res_tac L1_TO_IL1_CORRECTNESS_LEMMA
THEN fs [FST, SND]
THEN res_tac
THEN `bs_il1 (IL1_Expr te, fs') (l1_il1_val v) fs'` by (rw [Once bs_il1_cases] THEN metis_tac [])
THEN metis_tac []);

val L1_TO_IL1_FORALL_CORRECTNESS_THM = store_thm("L1_TO_IL1_FORALL_CORRECTNESS_THM",
``!e s v s' s''.big_step (e, s) v s' ==> !s'' v'.bs_il1 (l1_to_il1 e 0, con_store s) v' s'' ==> equiv (con_store s') s'' /\ (l1_il1_val v = v')``,
rw [l1_to_il1_def] THEN `?s te lc.l1_to_il1_pair 0 e = (s,te, lc)` by total THEN fs [LET_DEF] THEN fs [Once bs_il1_cases] THEN imp_res_tac IL1_EXPR_BACK_THM
THEN rw [] THEN imp_res_tac L1_TO_IL1_CORRECTNESS_LEMMA THEN fs [FST, SND] THEN `equiv (con_store s) (con_store s)` by metis_tac [EQUIV_REFL_THM] THEN imp_res_tac EQ_SYM THEN res_tac THEN imp_res_tac IL1_DETERMINACY_THM THEN rw [] THEN metis_tac [BS_IL1_EXPR_DETERMINACY]);

val STORE_DOMAIN_INVERSE_THM = store_thm("STORE_DOMAIN_INVERSE_THM",
``!l s.User l ∈ FDOM (con_store s) ==> l ∈ FDOM s``,
rw [con_store_def, FDOM_DEF, MAP_KEYS_def]);

val no_red_l1_def = Define `no_red_l1 = B_Plus (B_Value (B_N 0)) (B_Value (B_B T))`;

val no_red_l1_thm = store_thm("no_red_l1_thm", ``!s v s'.~big_step(no_red_l1, s) v s'``, rw [no_red_l1_def, Once big_step_cases] THEN CCONTR_TAC THEN fs[] THEN rw [] THEN `~big_step (B_Value (B_B T), s''') (B_N n2) s'` by fs [Once big_step_cases]);

val unwind_l1_def = Define `
(unwind_l1 0 e1 _ = B_If e1 no_red_l1 (B_Value B_Skip)) /\
(unwind_l1 (SUC n) e1 e2 = B_If e1 (B_Seq e2 (unwind_l1 n e1 e2)) (B_Value B_Skip))`;

val no_red_il1_def = Define `no_red_il1 = IL1_Expr (IL1_Plus (IL1_Value (IL1_Integer 0)) (IL1_Value (IL1_Boolean T)))`;

val no_red_il1_thm = store_thm("no_red_il1_thm", ``!s v s'.~bs_il1(no_red_il1, s) v s'``, rw [no_red_il1_def, Once bs_il1_cases, Once bs_il1_expr_cases] THEN CCONTR_TAC THEN fs[] THEN rw [] THEN `~bs_il1_expr (IL1_Value (IL1_Boolean T), s) (IL1_Integer n2)` by fs [Once bs_il1_expr_cases]);

val unwind_il1_def = Define `
(unwind_il1 0 e1 _ = IL1_SIf e1 no_red_il1 (IL1_Expr (IL1_Value IL1_ESkip))) /\
(unwind_il1 (SUC n) e1 e2 = IL1_SIf e1 (IL1_Seq e2 (unwind_il1 n e1 e2)) (IL1_Expr (IL1_Value (IL1_ESkip))))
`;

val unwind_l1_lemma = store_thm("unwind_l1_lemma",
``!p v s'.big_step p v s' ==> (v = B_Skip) ==> !e1 e2.(FST p = B_While e1 e2) ==> ?n'.!n.(n >= n') ==> big_step (unwind_l1 n e1 e2, SND p) v s'``,
ho_match_mp_tac big_step_strongind THEN rw [FST, SND]
THEN1 (`!n. (n >= SUC n') ==> big_step (unwind_l1 n e1 e2, s) B_Skip s'''` by (
rw [] THEN
Cases_on `n` THEN1 decide_tac
THEN
rw [unwind_l1_def] THEN
rw [Once big_step_cases] THEN
rw [Once (Q.SPECL [`(B_Seq e1 e2, s)`] big_step_cases)] THEN
`n'' >= n'` by decide_tac THEN
metis_tac [])
THEN metis_tac [])
THEN1 (
`!n. (n >= 0) ==> big_step (unwind_l1 n e1 e2, s) B_Skip s'` by (

Induct_on `n`

THEN1 (rw [Once big_step_cases, unwind_l1_def] THEN rw [Once (Q.SPECL [`(B_Value B_Skip, s)`] big_step_cases)])

THEN rw [unwind_l1_def]
THEN rw [Once big_step_cases]
THEN metis_tac [big_step_cases])
THEN metis_tac []));

val unwind_l1_2_lemma = store_thm("unwind_l1_2_lemma", 
``!n e1 e2 s s'.big_step (unwind_l1 n e1 e2, s) B_Skip s' ==> big_step (B_While e1 e2, s) B_Skip s'``,
Induct_on `n`
THEN1 (
rw [unwind_l1_def]
THEN fs [Once big_step_cases] THEN1 metis_tac [no_red_l1_thm]
THEN imp_res_tac BS_VALUE_BACK_THM THEN rw [])

THEN rw [unwind_l1_def]
THEN fs [Once (Q.SPECL [`(B_If e1 e2 e3, s')`] big_step_cases)]
THEN1 (
fs [Once (Q.SPECL [`(B_Seq e1 e2, s')`] big_step_cases)] THEN metis_tac [big_step_cases])

THEN imp_res_tac BS_VALUE_BACK_THM THEN rw [] THEN metis_tac [big_step_cases]);

val unwind_l1_thm = store_thm("unwind_l1_thm",
``!e1 e2 s s'.big_step (B_While e1 e2, s) B_Skip s' <=> ?n.big_step (unwind_l1 n e1 e2, s) B_Skip s'``,
rw [EQ_IMP_THM] THEN metis_tac [LESS_EQ_REFL, GREATER_EQ, unwind_l1_lemma, unwind_l1_2_lemma, FST, SND]);

val unwind_il1_lemma = store_thm("unwind_il1_lemma",
``!p v s'.bs_il1 p v s' ==> (v = IL1_ESkip) ==> !e1 e2.(FST p = IL1_While e1 e2) ==> ?n'.!n.(n >= n') ==> bs_il1 (unwind_il1 n e1 e2, SND p) v s'``,
ho_match_mp_tac bs_il1_strongind THEN rw [FST, SND]
THEN1 (`!n. (n >= SUC n') ==> bs_il1 (unwind_il1 n e1 e2, s) IL1_ESkip s''` by (
rw [] THEN
Cases_on `n` THEN1 decide_tac
THEN
rw [unwind_il1_def] THEN
rw [Once bs_il1_cases] THEN
rw [Once bs_il1_cases] THEN
`n'' >= n'` by decide_tac THEN
metis_tac [])
THEN metis_tac [])
THEN1 (
`!n. (n >= 0) ==> bs_il1 (unwind_il1 n e1 e2, s') IL1_ESkip s'` by (

Induct_on `n`

THEN1 (rw [Once bs_il1_cases, unwind_il1_def] THEN rw [Once (Q.SPECL [`(IL1_Expr X, s)`] bs_il1_cases), Once (Q.SPECL [`(IL1_Value IL1_ESkip, s')`] bs_il1_expr_cases)])

THEN rw [unwind_il1_def]
THEN rw [Once bs_il1_cases]
THEN rw [Once (Q.SPECL [`(IL1_Expr X, s)`] bs_il1_cases), Once (Q.SPECL [`(IL1_Value IL1_ESkip, s')`] bs_il1_expr_cases)])
THEN metis_tac []));

val unwind_il1_2_lemma = store_thm("unwind_il1_2_lemma", 
``!n e1 e2 s s'.bs_il1 (unwind_il1 n e1 e2, s) IL1_ESkip s' ==> bs_il1 (IL1_While e1 e2, s) IL1_ESkip s'``,
Induct_on `n`
THEN1 (
rw [unwind_il1_def]
THEN fs [Once bs_il1_cases] THEN1 metis_tac [no_red_il1_thm]
THEN imp_res_tac IL1_EXPR_BACK_THM THEN rw [])

THEN rw [unwind_il1_def]
THEN fs [Once (Q.SPECL [`(IL1_SIf e1 e2 e3, s')`] bs_il1_cases)]
THEN1 (
fs [Once (Q.SPECL [`(IL1_Seq e1 e2, s')`] bs_il1_cases)] THEN metis_tac [bs_il1_cases])

THEN imp_res_tac IL1_EXPR_BACK_THM THEN rw [] THEN metis_tac [bs_il1_cases]);

val unwind_il1_thm = store_thm("unwind_il1_thm",
``!e1 e2 s s'.bs_il1 (IL1_While e1 e2, s) IL1_ESkip s' <=> ?n'.bs_il1 (unwind_il1 n' e1 e2, s) IL1_ESkip s'``,
rw [EQ_IMP_THM] THEN metis_tac [GREATER_EQ, LESS_EQ_REFL, unwind_il1_lemma, unwind_il1_2_lemma, FST, SND]);

val _ = export_theory ();

