rule bet:
    output:
        stripped=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='stripped.nii.gz',**{'space':'MNI152NLin2009cAsym'}),
    #log: 'logs/bet/sub-{subject}_T1w.log'
    params:
        moving = expand(moving_volume, session=sessions, allow_missing=True),
    shell:
        'bet {params.moving} {output.stripped}'

rule align_mni_rigid:
    input:
        stripped=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='stripped.nii.gz',**{'space':'MNI152NLin2009cAsym'}),
    output:
        stripped_warped=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='stripped_aligned.nii.gz',**{'space':'MNI152NLin2009cAsym'}),
        xfm=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='xfm.mat',**{'space':'MNI152NLin2009cAsym'}),
    params:
        fixed = config['template'],
        dof = config['flirt']['dof'],
        coarse = config['flirt']['coarsesearch'],
        fine = config['flirt']['finesearch'],
        cost = config['flirt']['cost'],
        interp = config['flirt']['interp'],
    envmodules: 'fsl'
    #log: 'logs/align_mni_rigid/sub-{subject}_T1w.log'
    shell:
        'flirt -in {input.stripped} -ref {params.fixed} -out {output.stripped_warped} -omat {output.xfm} -dof {params.dof} -coarsesearch {params.coarse} -finesearch {params.fine} -cost {params.cost} -interp {params.interp}'

rule apply_xfm:
    input:
        xfm=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='xfm.mat',**{'space':'MNI152NLin2009cAsym'}),
    output:
        warped=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='T1w.nii.gz',**{'space':'MNI152NLin2009cAsym'}),
    params:
        moving = expand(moving_volume, session=sessions, allow_missing=True),
        fixed = config['template'],
    envmodules: 'fsl'
    shell:
        'flirt -in {params.moving} -ref {params.fixed} -applyxfm -init {input.xfm} -out {output.warped}'

rule fsl_to_ras:
    input:
        xfm=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='xfm.mat',**{'space':'MNI152NLin2009cAsym'}),
        warped=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='T1w.nii.gz',**{'space':'MNI152NLin2009cAsym'}),
    params:
        moving_vol = expand(moving_volume, session=sessions, allow_missing=True),
    output:
        xfm_new=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='xfm.txt',**{'space':'MNI152NLin2009cAsym','desc':'ras'}),
        tfm_new=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='xfm.tfm',**{'space':'MNI152NLin2009cAsym','desc':'ras'}),
    shell:
        'resources/c3d_affine_tool -ref {input.warped} -src {params.moving_vol} {input.xfm} -fsl2ras -o {output.xfm_new} && \
        resources/c3d_affine_tool -ref {input.warped} -src {params.moving_vol} {input.xfm} -fsl2ras -oitk {output.tfm_new}'

rule fid_tform_mni_rigid:
    input:
        xfm_new=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='xfm.txt',**{'space':'MNI152NLin2009cAsym','desc':'ras'}),
    params:
        bids_name(root=join(config['input_dir'],'deriv','afids'),kind='anat',subject='{subject}',session=None,suffix=suffix_afids,**{'space':'T1w','desc':'average'}),
        template = 'resources/dummy.fcsv',
    output:
        fcsv_new=bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix=suffix_afids,**{'space':'MNI152NLin2009cAsym','desc':'ras'}),
        reg_done = touch(bids_name(root=join(config['output_dir'],'deriv','mni_space'),kind='anat',subject='{subject}',suffix='registration.done')),
    #log: 'logs/fid_tform_mni_rigid/sub-{subject}_T1w.log'
    script:
        '../scripts/tform_script.py'
