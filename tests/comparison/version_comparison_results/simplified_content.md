the matching cost by performing two-pass aggregation using two orthogonal 1D windows [5], [6], [8]. The two-pass method first aggregates matching costs in the vertical direction, and then computes a weighted sum of the aggregated costs in the horizontal direction. Given that support regions are of size ω لا ω, the two-pass method reduces the complexity of cost aggregation from O(ω2) to O(ω).

# B. Temporal cost aggregation

Once aggregated costs C(p, p¯) have been computed for all pixels p in the reference image and their respective matching candidates p¯ in the target image, a single-pass temporal aggregation routine is exectuted. At each time instance, the algorithm stores an auxiliary cost Ca(p, p¯) which holds a weighted summation of costs obtained in the previous frames. During temporal aggregation, the auxiliary cost is merged with the cost obtained from the current frame using

![](/91bac018d450f4235937266522b6aa0de61f5651534c10332c96ed1937a7440d.jpg)

where the feedback coefficient λ controls the amount of cost smoothing and wt(p, pt-1) enforces color similarity in the temporal domain. The temporal adaptive weight computed between the pixel of interest p in the current frame and pixel pt-1, located at the same spatial coordinate in the prior frame, is given by

![](/428043e9cd4b0f8dabbdbe2e5e13171af2e0c914076d0dbf5b434e1626ea1dec.jpg)

where γt regulates the strength of grouping by color similarity in the temporal dimension. The temporal adaptive weight has the effect of preserving edges in the temporal domain, such that when a pixel coordinate transitions from one side of an edge to another in subsequent frames, the auxiliary cost is assigned a small weight and the majority of the cost is derived from the current frame.

# C. Disparity Selection and Confidence Assessment

Having performed temporal cost aggregation, matches are determined using the Winner-Takes-All (WTA) match selection criteria. The match for p, denoted as m(p), is the candidate pixel p¯ Sp characterized by the minimum matching cost, and is given by

![](/2ceed2b1dfb02e052b6a8959ea1e0ecd904e9cfc89761cbddb8656389d04ac5d.jpg)

To asses the level of confidence associated with selecting minimum cost matches, the algorithm determines another set of matches, this time from the target to reference image, and verifies if the results agree. Given that p¯ = m(p), i.e. pixel p¯ in the right image is the match for pixel p in the left image, and p 0 = m(¯p), the confidence measure Fp is computed as

![](/12c93e1fa55596d9e9acde65c77e9f7ac429e5fabb912f4de6db727c8b46b07f.jpg)

# D. Iterative Disparity Refinement

Once the first iteration of stereo matching is complete, disparity estimates D ip can be used to guide matching in subsequent iterations. This is done by penalizing disparities that deviate from their expected values. The penalty function is given by

![](/27c620a0fb50e95f13bee57847d91e6ee67e858646d916c1fb9022e7babb5c47.jpg)

where the value of α is chosen empirically. Next, the penalty values are incorporated into the matching cost as

![](/c8f02d71a28b779e04a990aa2460c9c5832e084c08dd5de661b75f8d7f93201c.jpg)

and the matches are reselected using the WTA match selection criteria. The resulting disparity maps are then post-processed using a combination of median filtering and occlusion filling. Finally, the current cost becomes the auxiliary cost for the next pair of frames in the video sequence, i.e., Ca(p, p¯) ← C(p, p¯) for all pixels p in the and their matching candidates p¯.

# IV. RESULTS

The speed and accuracy of real-time stereo matching algorithms are traditionally demonstrated using still-frame images from the Middlebury stereo benchmark [1], [2]. Still frames, however, are insufficient for evaluating stereo matching algorithms that incorporate frame-to-frame prediction to enhance matching accuracy. An alternative approach is t o use a stereo video sequence with a ground truth disparity for each frame. Obtaining the ground truth disparity of real world video sequences is a difficult undertaking due to the high frame rate of video and limitations in depth sensingtechnology. To address the need for stereo video with ground truth disparities, five pairs of synthetic stereo video sequences of a computer-generated scene were given in [19]. While these videos incorporate a sufficient amount of movement variation, they were generated from relatively simple models using lowresolution rendering, and they do not provide occlusion or discontinuity maps.

To evaluate the performance of temporal aggregation, a new synthetic stereo video sequence is introduced along with corresponding disparity maps, occlusion maps, and discontinuity maps for evaluating the performance of temporal stereo matching algorithms. To create the video sequence, a complex scene was constructed using Google Sketchup and a pair of animated paths were rendered photorealistically using the Kerkythea rendering software. Realistic material properties were used to give surfaces a natural-looking appearance by adjusting their specularity, reflectance, and diffusion. The video sequence has a resolution of 640 لا 480 pixels, a frame rate of 30 frames per second, and a duration of 4 seconds. In addition to performing photorealistic rendering, depth renders of both video sequences were also generated and converted to ground truth disparity for the stereo video. The video sequences and ground truth data have been made available at http://mc2. unl. edu/current-research /image-processing/. Figure 2 shows two sample frames