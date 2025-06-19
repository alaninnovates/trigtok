import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Transcript } from './transcript';

export class Database {
    private client: SupabaseClient;

    constructor(supabaseUrl: string, supabaseKey: string) {
        this.client = createClient(supabaseUrl, supabaseKey);
    }

    public async explanationExists(
        unitId: number,
        topicId: number,
    ): Promise<{
        exists: boolean;
        error: boolean;
        data: any;
    }> {
        const { data, error } = await this.client
            .from('explanations')
            .select('id, transcript, audio_url')
            .eq('unit', unitId)
            .eq('topic', topicId)
            .limit(1);

        if (error) {
            return {
                exists: false,
                error: true,
                data: error.message,
            };
        }

        return {
            exists: data.length > 0,
            error: false,
            data,
        };
    }

    public async getUnitInfo(unitId: number): Promise<{
        className: string;
        unitName: string;
    } | null> {
        const { data, error } = await this.client
            .from('units')
            .select('name, classes(name)')
            .eq('id', unitId)
            .single();

        if (error) {
            console.error('Error fetching unit:', error);
            return null;
        }

        return data
            ? {
                  // @ts-ignore
                  className: data.classes.name,
                  unitName: data.name,
              }
            : null;
    }

    public async storeExplanation(
        unitId: number,
        topicId: number,
        transcript: Transcript,
        audioUrl: string,
    ): Promise<{
        success: boolean;
        data: any;
    }> {
        const { data, error } = await this.client
            .from('explanations')
            .insert({
                unit: unitId,
                topic: topicId,
                transcript: transcript,
                audio_url: audioUrl,
            })
            .select('*')
            .single();

        if (error) {
            return {
                success: false,
                data: error.message,
            };
        }

        return {
            success: true,
            data,
        };
    }

    public async createSet(
        title: string,
        subject: string,
        content: string,
        files: string[],
        supabaseUserId: string,
    ) {
        const { data, error } = await this.client
            .from('sets')
            .insert({
                profile_id: supabaseUserId,
                title,
                subject,
                content,
                files,
            })
            .select('*')
            .single();

        if (error) {
            console.error('Error creating set:', error);
            return null;
        }

        return data;
    }
}
